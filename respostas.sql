-- ========================================
-- Quest�o 1: Crie uma query que obtenha a lista de produtos (ProductName), e a quantidade por unidade (QuantityPerUnit);
-- ========================================
SELECT 
	ProductName
	,QuantityPerUnit
FROM 
	Products;

-- ========================================
-- Quest�o 2: Crie uma query que obtenha a lista de produtos ativos (ProductID e ProductName);
-- ========================================
SELECT 
	ProductID
	,ProductName
FROM 
	Products
WHERE 
	Discontinued = 0;

-- ========================================
-- Quest�o 3: Crie uma query que obtenha a lista de produtos descontinuados (ProductID e ProductName);
-- ========================================
SELECT 
	ProductID
	,ProductName
FROM 
	Products
WHERE 
	Discontinued = 1;

-- ========================================
-- Quest�o 4: Crie uma query que obtenha a lista de produtos (ProductID, ProductName, UnitPrice) ativos, onde o custo dos produtos s�o menores que $20;
-- ========================================
SELECT 
	ProductID
	,ProductName
	,UnitPrice
FROM 
	Products
WHERE 
	1=1
	AND Discontinued = 0
	AND UnitPrice < 20;	

-- ========================================
-- Quest�o 5: Crie uma query que obtenha a lista de produtos (ProductID, ProductName, UnitPrice) ativos, onde o custo dos produtos s�o entre $15 e $25;
-- ========================================
SELECT 
	ProductID
	,ProductName
	,UnitPrice
FROM 
	Products
WHERE 
	1=1
	AND Discontinued = 0
	AND UnitPrice BETWEEN 15 AND 25;	

-- ========================================
-- Quest�o 6: Crie uma query que obtenha a lista de produtos (ProductName, UnitPrice) que tem pre�o acima da m�dia;
-- ========================================
SELECT 
    ProductName
	,UnitPrice
FROM 
    Products
WHERE 
    UnitPrice > (
        SELECT AVG(UnitPrice)
        FROM Products
    );

-- ========================================
-- Quest�o 7 - Parte 1: Crie uma procedure que retorne cada produto e seu pre�o
-- ========================================
CREATE OR ALTER PROCEDURE sp_ListarProdutosPrecos
AS
BEGIN
    SELECT 
         ProductID
        ,ProductName
        ,UnitPrice
    FROM 
        Products;
END;

-- ========================================
-- ========================================
-- Quest�o 7.a - Alternativa 1 (LIKE com m�ltiplos valores)
-- ========================================
CREATE OR ALTER PROCEDURE sp_ListarProdutosPrecos
    @Codigo_Fornecedor NVARCHAR(MAX) = NULL,
    @Codigo_Categoria NVARCHAR(MAX) = NULL
AS
BEGIN
    SELECT 
         ProductID
        ,ProductName
        ,UnitPrice
        ,SupplierID
        ,CategoryID
    FROM 
        Products
    WHERE 1=1
        AND (
            @Codigo_Fornecedor IS NULL
            OR ',' + @Codigo_Fornecedor + ',' LIKE '%,' + CAST(SupplierID AS NVARCHAR) + ',%'
        )
        AND (
            @Codigo_Categoria IS NULL
            OR ',' + @Codigo_Categoria + ',' LIKE '%,' + CAST(CategoryID AS NVARCHAR) + ',%'
        );
END;

-- ========================================
-- Quest�o 7.a - Alternativa 2 (STRING_SPLIT)
-- ========================================
CREATE OR ALTER PROCEDURE sp_ListarProdutosPrecos
    @Codigo_Fornecedor NVARCHAR(MAX) = NULL,
    @Codigo_Categoria NVARCHAR(MAX) = NULL
AS
BEGIN
    SELECT 
         p.ProductID
        ,p.ProductName
        ,p.UnitPrice
        ,p.SupplierID
        ,p.CategoryID
    FROM 
        Products p
    WHERE 1=1
        AND (
            @Codigo_Fornecedor IS NULL
            OR EXISTS (
                SELECT 1
                FROM 
                    STRING_SPLIT(@Codigo_Fornecedor, ',') f
                WHERE 
                    TRY_CAST(f.value AS INT) = p.SupplierID
            )
        )
        AND (
            @Codigo_Categoria IS NULL
            OR EXISTS (
                SELECT 1
                FROM 
                    STRING_SPLIT(@Codigo_Categoria, ',') c
                WHERE 
                    TRY_CAST(c.value AS INT) = p.CategoryID
            )
        );
END;

-- ========================================
-- Quest�o 7.b - Alternativa 1 (LIKE + OLTP/OLAP)
-- ========================================
CREATE OR ALTER PROCEDURE sp_ListarProdutosPrecos
    @Codigo_Fornecedor NVARCHAR(MAX) = NULL,
    @Codigo_Categoria NVARCHAR(MAX) = NULL,
    @Codigo_Transportadora NVARCHAR(MAX) = NULL,
    @Tipo_Saida VARCHAR(10) = 'OLTP'
AS
BEGIN
    IF @Tipo_Saida = 'OLTP'
    BEGIN
        SELECT 
             p.ProductID
            ,p.ProductName
            ,p.UnitPrice
            ,p.SupplierID
            ,p.CategoryID
            ,o.ShipVia AS Codigo_Transportadora
        FROM 
            Products p
            INNER JOIN [Order Details] od 
                ON p.ProductID = od.ProductID
            INNER JOIN Orders o 
                ON o.OrderID = od.OrderID
        WHERE 1=1
            AND (
                @Codigo_Fornecedor IS NULL 
                OR ',' + @Codigo_Fornecedor + ',' LIKE '%,' + CAST(p.SupplierID AS NVARCHAR) + ',%'
            )
            AND (
                @Codigo_Categoria IS NULL 
                OR ',' + @Codigo_Categoria + ',' LIKE '%,' + CAST(p.CategoryID AS NVARCHAR) + ',%'
            )
            AND (
                @Codigo_Transportadora IS NULL 
                OR ',' + @Codigo_Transportadora + ',' LIKE '%,' + CAST(o.ShipVia AS NVARCHAR) + ',%'
            );
    END
    ELSE IF @Tipo_Saida = 'OLAP'
    BEGIN
        SELECT 
             p.ProductName
            ,AVG(CASE WHEN o.ShipVia = 1 THEN p.UnitPrice END) AS Media_Transportadora_1
            ,AVG(CASE WHEN o.ShipVia = 2 THEN p.UnitPrice END) AS Media_Transportadora_2
            ,AVG(CASE WHEN o.ShipVia = 3 THEN p.UnitPrice END) AS Media_Transportadora_3
        FROM 
            Products p
            INNER JOIN [Order Details] od 
                ON p.ProductID = od.ProductID
            INNER JOIN Orders o 
                ON o.OrderID = od.OrderID
        WHERE 1=1
            AND (
                @Codigo_Fornecedor IS NULL 
                OR ',' + @Codigo_Fornecedor + ',' LIKE '%,' + CAST(p.SupplierID AS NVARCHAR) + ',%'
            )
            AND (
                @Codigo_Categoria IS NULL 
                OR ',' + @Codigo_Categoria + ',' LIKE '%,' + CAST(p.CategoryID AS NVARCHAR) + ',%'
            )
            AND (
                @Codigo_Transportadora IS NULL 
                OR ',' + @Codigo_Transportadora + ',' LIKE '%,' + CAST(o.ShipVia AS NVARCHAR) + ',%'
            )
        GROUP BY 
            p.ProductName;
    END
END;

-- ========================================
-- Quest�o 7.b - Alternativa 2 (STRING_SPLIT + OLTP/OLAP)
-- ========================================
CREATE OR ALTER PROCEDURE sp_ListarProdutosPrecos
    @Codigo_Fornecedor NVARCHAR(MAX) = NULL,
    @Codigo_Categoria NVARCHAR(MAX) = NULL,
    @Codigo_Transportadora NVARCHAR(MAX) = NULL,
    @Tipo_Saida VARCHAR(10) = 'OLTP'
AS
BEGIN
    IF @Tipo_Saida = 'OLTP'
    BEGIN
        SELECT 
             p.ProductID
            ,p.ProductName
            ,p.UnitPrice
            ,p.SupplierID
            ,p.CategoryID
            ,o.ShipVia AS Codigo_Transportadora
        FROM 
            Products p
            INNER JOIN [Order Details] od 
                ON p.ProductID = od.ProductID
            INNER JOIN Orders o 
                ON o.OrderID = od.OrderID
        WHERE 1=1
            AND (
                @Codigo_Fornecedor IS NULL OR EXISTS (
                    SELECT 1 FROM STRING_SPLIT(@Codigo_Fornecedor, ',') f 
                    WHERE TRY_CAST(f.value AS INT) = p.SupplierID
                )
            )
            AND (
                @Codigo_Categoria IS NULL OR EXISTS (
                    SELECT 1 
                    FROM 
                        STRING_SPLIT(@Codigo_Categoria, ',') c 
                    WHERE 
                        TRY_CAST(c.value AS INT) = p.CategoryID
                )
            )
            AND (
                @Codigo_Transportadora IS NULL OR EXISTS (
                    SELECT 1 
                    FROM 
                        STRING_SPLIT(@Codigo_Transportadora, ',') t 
                    WHERE 
                        TRY_CAST(t.value AS INT) = o.ShipVia
                )
            );
    END
    ELSE IF @Tipo_Saida = 'OLAP'
    BEGIN
        SELECT 
             p.ProductName
            ,AVG(CASE WHEN o.ShipVia = 1 THEN p.UnitPrice END) AS Media_Transportadora_1
            ,AVG(CASE WHEN o.ShipVia = 2 THEN p.UnitPrice END) AS Media_Transportadora_2
            ,AVG(CASE WHEN o.ShipVia = 3 THEN p.UnitPrice END) AS Media_Transportadora_3
        FROM 
            Products p
            INNER JOIN [Order Details] od 
                ON p.ProductID = od.ProductID
            INNER JOIN Orders o 
                ON o.OrderID = od.OrderID
        WHERE 1=1
            AND (
                @Codigo_Fornecedor IS NULL OR EXISTS (
                    SELECT 1 
                    FROM 
                        STRING_SPLIT(@Codigo_Fornecedor, ',') f 
                    WHERE 
                        TRY_CAST(f.value AS INT) = p.SupplierID
                )
            )
            AND (
                @Codigo_Categoria IS NULL OR EXISTS (
                    SELECT 1 
                    FROM 
                        STRING_SPLIT(@Codigo_Categoria, ',') c 
                    WHERE 
                        TRY_CAST(c.value AS INT) = p.CategoryID
                )
            )
            AND (
                @Codigo_Transportadora IS NULL OR EXISTS (
                    SELECT 1 
                    FROM 
                        STRING_SPLIT(@Codigo_Transportadora, ',') t 
                    WHERE 
                        TRY_CAST(t.value AS INT) = o.ShipVia
                )
            )
        GROUP BY 
            p.ProductName;
    END
END;

-- ========================================
-- Quest�o 8: Crie uma query que obtenha a lista de empregados e seus liderados, caso o empregado n�o possua liderado, informar 'N�o possui liderados'.
-- ========================================
SELECT 
     e.EmployeeID AS LiderID
    ,e.FirstName + ' ' + e.LastName AS Lider
    ,ISNULL(l.FirstName + ' ' + l.LastName, 'N�o possui liderados') AS Liderado
FROM 
    Employees e
LEFT JOIN 
    Employees l 
    ON l.ReportsTo = e.EmployeeID
ORDER BY 
     e.EmployeeID
    ,Liderado;

-- ========================================
-- Quest�o 9: Crie uma query que obtenha o(s) produto(s) mais caro(s) e o(s) mais barato(s) da lista (ProductName e UnitPrice);
-- ========================================
SELECT 
     ProductName
    ,UnitPrice
FROM 
    Products
WHERE 
    UnitPrice = (SELECT MIN(UnitPrice) FROM Products)
    OR 
    UnitPrice = (SELECT MAX(UnitPrice) FROM Products)
ORDER BY 
    UnitPrice ASC, ProductName;

-- ========================================
-- Quest�o 10: Crie uma query que obtenha a lista de pedidos dos funcion�rios da regi�o 'Western';
-- ========================================
SELECT 
     o.OrderID
    ,o.OrderDate
    ,o.EmployeeID
    ,e.FirstName + ' ' + e.LastName AS Funcionario
FROM 
    Orders o
INNER JOIN 
    Employees e 
    ON o.EmployeeID = e.EmployeeID
INNER JOIN 
    EmployeeTerritories et 
    ON e.EmployeeID = et.EmployeeID
INNER JOIN 
    Territories t 
    ON et.TerritoryID = t.TerritoryID
INNER JOIN 
    Region r 
    ON t.RegionID = r.RegionID
WHERE 1=1
    AND r.RegionDescription = 'Western'
ORDER BY 
     o.OrderDate;


-- ========================================
-- Quest�o 11: Crie uma query que obtenha os n�meros de pedidos e a lista de clientes (CompanyName, ContactName, Address e Phone), que possuam 171 como c�digo de �rea do telefone e que o frete dos pedidos custem entre $6.00 e $13.00;
-- ========================================
SELECT 
     o.OrderID
    ,c.CompanyName
    ,c.ContactName
    ,c.Address
    ,c.Phone
FROM 
    Orders o
INNER JOIN 
    Customers c 
    ON o.CustomerID = c.CustomerID
WHERE 1=1
    AND c.Phone LIKE '(171)%'
    AND o.Freight BETWEEN 6.00 AND 13.00
ORDER BY 
    o.OrderID;

-- ========================================
-- Quest�o 12: Crie uma query que obtenha todos os dados de pedidos (Orders) que envolvam os fornecedores da cidade 'Manchester' e foram enviados pela empresa 'Speedy Express';
-- ========================================
SELECT 
     o.*
FROM 
    Orders o
INNER JOIN 
    [Order Details] od 
    ON o.OrderID = od.OrderID
INNER JOIN 
    Products p 
    ON od.ProductID = p.ProductID
INNER JOIN 
    Suppliers s 
    ON p.SupplierID = s.SupplierID
INNER JOIN 
    Shippers sh 
    ON o.ShipVia = sh.ShipperID
WHERE 1=1
    AND s.City = 'Manchester'
    AND sh.CompanyName = 'Speedy Express';

-- ========================================
-- Quest�o 13: Crie uma query que obtenha a lista de Produtos (ProductName) constantes nos Detalhe dos Pedidos (Order Details), calculando o valor total de cada produto j� aplicado o desconto % (se tiver algum);
-- ========================================
SELECT 
     p.ProductName
    ,ROUND(
        SUM(
            od.UnitPrice * od.Quantity * (1 - od.Discount)
        )
        ,2
    ) AS TotalComDesconto
FROM 
    [Order Details] od
INNER JOIN 
    Products p 
    ON od.ProductID = p.ProductID
GROUP BY 
    p.ProductName
ORDER BY 
    TotalComDesconto DESC;

