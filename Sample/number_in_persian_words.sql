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
                        WHEN 1 THEN N'یک'
                        WHEN 2 THEN N'دو'
                        WHEN 3 THEN N'سه'
                        WHEN 4 THEN N'چهار'
                        WHEN 5 THEN N'پنج'
                        WHEN 6 THEN N'شش'
                        WHEN 7 THEN N'هفت'
                        WHEN 8 THEN N'هشت'
                        WHEN 9 THEN N'نه'
                        END
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 1 AND [digit_lag] = 0 THEN N'ده'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 1 AND [digit_lag] = 1 THEN N'یازده'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 1 AND [digit_lag] = 2 THEN N'دوازده'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 1 AND [digit_lag] = 3 THEN N'سیزده'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 1 AND [digit_lag] = 4 THEN N'چهارده'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 1 AND [digit_lag] = 5 THEN N'پانزده'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 1 AND [digit_lag] = 6 THEN N'شانزده'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 1 AND [digit_lag] = 7 THEN N'هفتده'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 1 AND [digit_lag] = 8 THEN N'هجده'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 1 AND [digit_lag] = 9 THEN N'نوزده'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 2 THEN N'بیست'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 3 THEN N'سی'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 4 THEN N'چهل'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 5 THEN N'پنجاه'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 6 THEN N'شصت'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 7 THEN N'هفتاد'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 8 THEN N'هشتاد'
                WHEN [digit] != 0 AND [position] % 3 = 2 AND [digit] = 9 THEN N'نود'
                WHEN [digit] != 0 AND [position] % 3 = 0 AND [digit] = 1 THEN N'صد'
                WHEN [digit] != 0 AND [position] % 3 = 0 AND [digit] = 2 THEN N'دویست'
                WHEN [digit] != 0 AND [position] % 3 = 0 AND [digit] = 3 THEN N'سیصد'
                WHEN [digit] != 0 AND [position] % 3 = 0 AND [digit] = 4 THEN N'چهارصد'
                WHEN [digit] != 0 AND [position] % 3 = 0 AND [digit] = 5 THEN N'پانصد'
                WHEN [digit] != 0 AND [position] % 3 = 0 AND [digit] = 6 THEN N'ششصد'
                WHEN [digit] != 0 AND [position] % 3 = 0 AND [digit] = 7 THEN N'هفتصد'
                WHEN [digit] != 0 AND [position] % 3 = 0 AND [digit] = 8 THEN N'هشتصد'
                WHEN [digit] != 0 AND [position] % 3 = 0 AND [digit] = 9 THEN N'نهصد'
                END AS [digit]
            ,CASE
                WHEN [digit] != 0 AND [position] / 4 = 1 AND [position] % 4 IN (0, 1, 2) THEN N'هزار'
                WHEN [digit] != 0 AND [position] / 7 = 1 AND [position] % 7 IN (0, 1, 2) THEN N'میلیون'
                WHEN [digit] != 0 AND [position] / 10 = 1 AND [position] % 10 IN (0, 1, 2) THEN N'میلیارد'
                WHEN [digit] != 0 AND [position] / 13 = 1 AND [position] % 13 IN (0, 1, 2) THEN N'بیلیون'
                WHEN [digit] != 0 AND [position] / 16 = 1 AND [position] % 16 IN (0, 1, 2) THEN N'بیلیارد'
                WHEN [digit] != 0 AND [position] / 19 = 1 AND [position] % 19 IN (0, 1, 2) THEN N'تریلیون'
                END AS [group]
        FROM [cte_ii])
    ,[cte_iv] AS (
        SELECT [id]
            ,[group]
            ,MIN([position]) AS [position]
            ,STRING_AGG([digit], N' و ') WITHIN GROUP (ORDER BY [position] DESC) AS [digit]
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
            ,STRING_AGG([name], N' و ') WITHIN GROUP (ORDER BY [position] DESC) AS [name]
        FROM [cte_v]
        WHERE [name] != ''
        GROUP BY [id])
SELECT [id]
    ,[name]
FROM [cte_vi]