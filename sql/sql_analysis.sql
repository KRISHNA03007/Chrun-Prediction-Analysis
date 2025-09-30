-- Checking whether all rows are imported or not 
USE db2;
SELECT * FROM churn_modelling;


-- 1. Customers with above-average balance in their geography
SELECT Geography, CustomerId, Balance
FROM Churn_Modelling c
WHERE Balance > (
    SELECT AVG(Balance) 
    FROM Churn_Modelling 
    WHERE Geography = c.Geography
);

-- 2. Exit rate by geography and gender
SELECT Geography,
       SUM(CASE WHEN Gender = 'Male' AND Exited = 1 THEN 1 ELSE 0 END) * 100.0 / SUM(CASE WHEN Gender = 'Male' THEN 1 ELSE 0 END) AS Male_ExitRate,
       SUM(CASE WHEN Gender = 'Female' AND Exited = 1 THEN 1 ELSE 0 END) * 100.0 / SUM(CASE WHEN Gender = 'Female' THEN 1 ELSE 0 END) AS Female_ExitRate
FROM Churn_Modelling
GROUP BY Geography;

-- 3. Top 5 customers with the highest balance per geography
SELECT Geography, CustomerId, Balance
FROM (
    SELECT Geography, CustomerId, Balance,
           ROW_NUMBER() OVER (PARTITION BY Geography ORDER BY Balance DESC) AS rn
    FROM Churn_Modelling
) ranked
WHERE rn <= 5;


-- 4. Churn rate by credit score range
SELECT CASE 
            WHEN CreditScore < 500 THEN 'Very Low'
            WHEN CreditScore BETWEEN 500 AND 650 THEN 'Low'
            WHEN CreditScore BETWEEN 651 AND 750 THEN 'Medium'
            ELSE 'High'
       END AS CreditScoreRange,
       COUNT(*) AS TotalCustomers,
       SUM(Exited) AS ChurnedCustomers,
       ROUND(SUM(Exited) * 100.0 / COUNT(*), 2) AS ChurnRate
FROM Churn_Modelling
GROUP BY CreditScoreRange;

-- 5. Running average balance by age
SELECT Age, CustomerId, Balance,
       AVG(Balance) OVER (PARTITION BY Age ORDER BY CustomerId) AS RunningAvgBalance
FROM Churn_Modelling;


-- 6. Which tenure group has the highest churn?
SELECT Tenure, 
       COUNT(*) AS TotalCustomers,
       SUM(Exited) AS Churned,
       ROUND(SUM(Exited) * 100.0 / COUNT(*), 2) AS ChurnRate
FROM Churn_Modelling
GROUP BY Tenure
ORDER BY ChurnRate DESC;


--7. Geography with the highest average salary among churned customers
SELECT Geography, AVG(EstimatedSalary) AS AvgSalary
FROM Churn_Modelling
WHERE Exited = 1
GROUP BY Geography
ORDER BY AvgSalary DESC
LIMIT 1;


--8. Customers with multiple products but inactive
SELECT CustomerId, Geography, Gender, NumOfProducts, IsActiveMember
FROM Churn_Modelling
WHERE NumOfProducts > 1 AND IsActiveMember = 0;


--9. Dense ranking customers by balance within each geography
SELECT Geography, CustomerId, Balance,
       DENSE_RANK() OVER (PARTITION BY Geography ORDER BY Balance DESC) AS BalanceRank
FROM Churn_Modelling;


--10. Percentage of customers with credit card across geographies
SELECT Geography,
       SUM(HasCrCard) * 100.0 / COUNT(*) AS PctWithCreditCard
FROM Churn_Modelling
GROUP BY Geography;


--11. Customers whose balance is higher than their geography’s average balance
SELECT c.CustomerId, c.Geography, c.Balance
FROM Churn_Modelling c
JOIN (
    SELECT Geography, AVG(Balance) AS AvgBal
    FROM Churn_Modelling
    GROUP BY Geography
) g ON c.Geography = g.Geography
WHERE c.Balance > g.AvgBal;


--12. Moving average of churn by age (window function)
SELECT Age,
       AVG(Exited) OVER (ORDER BY Age ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) AS MovingAvgChurn
FROM Churn_Modelling;


--13. Customers with salary in top 10% of their geography
SELECT CustomerId, Geography, EstimatedSalary
FROM (
    SELECT CustomerId, Geography, EstimatedSalary,
           NTILE(10) OVER (PARTITION BY Geography ORDER BY EstimatedSalary DESC) AS SalaryDecile
    FROM Churn_Modelling
) ranked
WHERE SalaryDecile = 1;


--14. Gender-wise churn distribution within each geography
SELECT Geography, Gender,
       COUNT(*) AS Total,
       SUM(Exited) AS Churned,
       ROUND(SUM(Exited) * 100.0 / COUNT(*), 2) AS ChurnRate
FROM Churn_Modelling
GROUP BY Geography, Gender;


-- 15. Customers whose credit score is below their geography’s average credit score
SELECT c.CustomerId, c.Geography, c.CreditScore
FROM Churn_Modelling c
JOIN (
    SELECT Geography, AVG(CreditScore) AS AvgScore
    FROM Churn_Modelling
    GROUP BY Geography
) g ON c.Geography = g.Geography
WHERE c.CreditScore < g.AvgScore;


--16. Age group vs average balance & churn
SELECT CASE
           WHEN Age < 30 THEN 'Under 30'
           WHEN Age BETWEEN 30 AND 50 THEN '30-50'
           ELSE '50+'
       END AS AgeGroup,
       AVG(Balance) AS AvgBalance,
       ROUND(SUM(Exited) * 100.0 / COUNT(*), 2) AS ChurnRate
FROM Churn_Modelling
GROUP BY AgeGroup;


-- 17. Customers who churned despite having high balance & high credit score
SELECT CustomerId, Geography, Balance, CreditScore
FROM Churn_Modelling
WHERE Exited = 1
  AND Balance > (SELECT AVG(Balance) FROM Churn_Modelling)
  AND CreditScore > (SELECT AVG(CreditScore) FROM Churn_Modelling);


--18. Average balance by tenure for active vs inactive customers
SELECT Tenure, IsActiveMember,
       AVG(Balance) AS AvgBalance
FROM Churn_Modelling
GROUP BY Tenure, IsActiveMember
ORDER BY Tenure, IsActiveMember;


--19. Top 3 geographies with the highest churn rate
SELECT Geography,
       ROUND(SUM(Exited) * 100.0 / COUNT(*), 2) AS ChurnRate
FROM Churn_Modelling
GROUP BY Geography
ORDER BY ChurnRate DESC
LIMIT 3;


--20. Customers in top 5% of balance but still churned
SELECT CustomerId, Geography, Balance
FROM (
    SELECT CustomerId, Geography, Balance,
           NTILE(20) OVER (ORDER BY Balance DESC) AS BalancePercentile
    FROM Churn_Modelling
) ranked
WHERE BalancePercentile = 1 AND Exited = 1;