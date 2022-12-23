WITH [cte] AS (
        SELECT [id]
            ,CONVERT([bigint], [number]) AS [number]
        FROM (VALUES (1, 987654321)
                ,(2, 123456789)) AS [T]([id], [number]))
    ,[cte_i] AS (
        SELECT [id], [number], [number] % POWER(10, 1) / POWER(10, 0) AS [digit], (1) AS [position]
        FROM [cte]
        UNION ALL
        SELECT [id], [number], [number] % POWER(CAST((10) AS [bigint]), [position] + 1) / POWER(CAST((10) AS [bigint]), [position]), [position] + 1
        FROM [cte_i]
        WHERE LEN([number]) != [position])
    ,[cte_ii] AS (
        SELECT [id]
            ,[number]
            ,[digit]
            ,[position]
            ,LEAD([digit]) OVER (PARTITION BY [id] ORDER BY [position]) AS [digit_lead]
            ,LAG([digit]) OVER (PARTITION BY [id] ORDER BY [position]) AS [digit_lag]
        FROM [cte_i])
    ,[cte_iii] AS (
        SELECT [id]
            ,[position]
            ,CASE
                WHEN [digit] != 0 AND [position] % 3 = 1 AND ([digit_lead] != 1 OR [digit_lead] IS NULL) THEN
                    CASE [digit]
                        WHEN 1 THEN 'One'
                        WHEN 2 THEN 'Two'
                        WHEN 3 THEN 'Three'
                        WHEN 4 THEN 'Four'
                        WHEN 5 THEN 'Five'
                        WHEN 6 THEN 'Six'
                        WHEN 7 THEN 'Seven'
                        WHEN 8 THEN 'Eight'
                        WHEN 9 THEN 'Nine'
                        END
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 1 AND [digit_lag] = 0 THEN 'Ten'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 1 AND [digit_lag] = 1 THEN 'Eleven'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 1 AND [digit_lag] = 2 THEN 'Twelve'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 1 AND [digit_lag] = 3 THEN 'Thirteen'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 1 AND [digit_lag] = 4 THEN 'Fourteen'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 1 AND [digit_lag] = 5 THEN 'Fifteen'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 1 AND [digit_lag] = 6 THEN 'Sixteen'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 1 AND [digit_lag] = 7 THEN 'Seventeen'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 1 AND [digit_lag] = 8 THEN 'Eighteen'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 1 AND [digit_lag] = 9 THEN 'Nineteen'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 2 THEN 'Twenty'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 3 THEN 'Thirty'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 4 THEN 'Forty'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 5 THEN 'Fifty'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 6 THEN 'Sixty'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 7 THEN 'Seventy'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 8 THEN 'Eighty'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 9 THEN 'Ninety'
                WHEN [digit] != 0 AND [position] % 3 = 0 AND [digit] = 1 THEN 'One Hundred'
                WHEN [digit] != 0 AND [position] % 3 = 0 AND [digit] = 2 THEN 'Two Hundred'
                WHEN [digit] != 0 AND [position] % 3 = 0 AND [digit] = 3 THEN 'Three Hundred'
                WHEN [digit] != 0 AND [position] % 3 = 0 AND [digit] = 4 THEN 'Four Hundred'
                WHEN [digit] != 0 AND [position] % 3 = 0 AND [digit] = 5 THEN 'Five Hundred'
                WHEN [digit] != 0 AND [position] % 3 = 0 AND [digit] = 6 THEN 'Six Hundred'
                WHEN [digit] != 0 AND [position] % 3 = 0 AND [digit] = 7 THEN 'Seven Hundred'
                WHEN [digit] != 0 AND [position] % 3 = 0 AND [digit] = 8 THEN 'Eight Hundred'
                WHEN [digit] != 0 AND [position] % 3 = 0 AND [digit] = 9 THEN 'Nine Hundred'
                END AS [digit]
            ,CASE
                WHEN [digit] != 0 AND [position] / 4 = 1 AND [position] % 4 IN (0, 1, 2) THEN 'Thousand'
                WHEN [digit] != 0 AND [position] / 7 = 1 AND [position] % 7 IN (0, 1, 2) THEN 'Million'
                WHEN [digit] != 0 AND [position] / 10 = 1 AND [position] % 10 IN (0, 1, 2) THEN 'Billion'
                WHEN [digit] != 0 AND [position] / 13 = 1 AND [position] % 13 IN (0, 1, 2) THEN 'Trillion'
                WHEN [digit] != 0 AND [position] / 16 = 1 AND [position] % 16 IN (0, 1, 2) THEN 'Quadrillion'
                WHEN [digit] != 0 AND [position] / 19 = 1 AND [position] % 19 IN (0, 1, 2) THEN 'Sextillion'
                END AS [group]
        FROM [cte_ii])
    ,[cte_iv] AS (
        SELECT [id]
            ,[group]
            ,MIN([position]) AS [position]
            ,STRING_AGG([digit], ' ') WITHIN GROUP (ORDER BY [position] DESC) AS [digit]
        FROM [cte_iii]
        GROUP BY [id]
            ,[group])
    ,[cte_v] AS (
        SELECT [id]
            ,[position]
            ,IIF([digit] IS NOT NULL, CONCAT([digit], IIF([group] IS NOT NULL, ' ', NULL), [group]), NULL) AS [name]
        FROM [cte_iv])
    ,[cte_vi] AS (
        SELECT [id]
            ,STRING_AGG([name], ', ') WITHIN GROUP (ORDER BY [position] DESC) AS [name]
        FROM [cte_v]
        WHERE [name] != ''
        GROUP BY [id])
SELECT [id]
    ,[name]
FROM [cte_vi]