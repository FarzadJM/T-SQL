DECLARE @xml_doc [xml] = 
		N'<MyTable>
			<MyRow>
				<PropertyI>abc</PropertyI>
				<PropertyII>987654310</PropertyII>
				<PropertyIII>12:00</PropertyIII>
				<PropertyIV>false</PropertyIV>
				<PropertyV>
					<PropertyVI>123</PropertyVI>
					<PropertyVII>456</PropertyVII>
				</PropertyV>
			</MyRow>
			<MyRow>
				<PropertyI>xyz</PropertyI>
				<PropertyII>0123456798</PropertyII>
				<PropertyIII>12:00</PropertyIII>
				<PropertyIV>NULL</PropertyIV>
				<PropertyV />
			</MyRow>
		</MyTable>',
	@json_doc [nvarchar](max) = NULL;

BEGIN

	SET NOCOUNT ON;

    DECLARE @doc_handle [int];

	EXEC sp_xml_preparedocument @doc_handle OUTPUT, @xml_doc;

	DECLARE @base TABLE (
		[id] [bigint],
		[parentid] [bigint],
		[localname] [nvarchar](4000),
		[sub] [nvarchar](max),
		[level] [bigint]);

	DECLARE @sample TABLE (
		[id] [bigint],
		[parentid] [bigint],
		[localname] [nvarchar](4000),
		[sub] [nvarchar](max),
		[level] [bigint]);

	WITH [parsed_xml] AS (
			SELECT [id] AS [id]
				,[parentid] AS [parentid]
				,[nodetype] AS [nodetype]
				,[localname] AS [localname]
				,[prefix] AS [prefix]
				,[namespaceuri] AS [namespaceuri]
				,[datatype] AS [datatype]
				,[prev] AS [prev]
				,REPLACE(REPLACE(CONVERT([nvarchar](max), [text]), CHAR(10), '\n'), CHAR(13), '\n') AS [text]
			FROM OPENXML (@doc_handle, '.', 1))
		,[cte] AS (
			SELECT [id]
				,[parentid]
				,[localname]
			FROM [parsed_xml]
			WHERE [parentid] IS NULL
			UNION ALL
			SELECT [parsed_xml].[id]
				,[parsed_xml].[parentid]
				,[parsed_xml].[localname]
			FROM [cte]
				JOIN [parsed_xml]
					ON [parsed_xml].[parentid] = [cte].[id]
						AND [parsed_xml].[nodetype] = 1)
		,[cte_vi] AS (
			SELECT DISTINCT [cte].[parentid]
				,[cte].[id]
				,[cte].[localname] AS [localname]
				,IIF([property].[localname] IS NULL, NULL,
					CONCAT('"', [property].[localname], '"', ' : '
						,CASE
							WHEN [value].[text] IS NULL THEN 'null'
							WHEN [value].[text] = 'null' THEN 'null'
							ELSE CONCAT('"', [value].[text], '"')
							END)) AS [sub]
			FROM [cte]
				JOIN [parsed_xml] AS [property]
					ON [property].[parentid] = [cte].[id]
						AND [property].[nodetype] = 1
				LEFT JOIN [parsed_xml] AS [value]
					ON [value].[parentid] = [property].[id])
		,[cte_ii] AS (
			SELECT [id]
				,[parentid]
				,[localname]
				,STRING_AGG([sub], ', ') AS [sub]
			FROM [cte_vi]
			GROUP BY [id]
				,[parentid]
				,[localname])
		,[cte_iii] AS (
			SELECT [id]
				,[parentid]
				,[localname]
				,[sub]
				,(1) AS [level]
			FROM [cte_ii]
			WHERE [parentid] IS NULL
			UNION ALL
			SELECT [cte_ii].[id]
				,[cte_ii].[parentid]
				,[cte_ii].[localname]
				,[cte_ii].[sub]
				,[cte_iii].[level] + (1) AS [level]
			FROM [cte_iii]
				JOIN [cte_ii]
					ON [cte_ii].[parentid] = [cte_iii].[id])
	INSERT INTO @base
	SELECT [id]
		,[parentid]
		,[localname]
		,IIF([sub] IS NULL, NULL, CONCAT('{', [sub], '}')) AS [sub]
		,[level]
	FROM [cte_iii];

	EXEC sp_xml_removedocument @doc_handle;

	WHILE ((SELECT MAX([level]) FROM @base) > 1)
	BEGIN

		WITH [cte] AS (
				SELECT MAX([level]) AS [max_level]
				FROM @base)
			,[cte_i] AS (
				SELECT [base].*
				FROM @base AS [base]
					JOIN [cte]
						ON [cte].[max_level] = [base].[level])
		INSERT INTO @sample
		SELECT *
		FROM [cte_i];

		WITH [cte] AS (
				SELECT [parentid]
					,[localname]
					,STRING_AGG([sub], ',') AS [sub]
				FROM @sample
				GROUP BY [parentid]
					,[localname])
			,[cte_i] AS (
				SELECT [parentid]
					,[localname]
					,IIF([sub] IS NULL, NULL, CONCAT('[', [sub], ']')) AS [sub]
				FROM [cte])
			,[cte_ii] AS (
				SELECT [id]
					,[parentid]
					,[localname]
					,[sub]
					,(1) AS [level]
				FROM @base AS [base]
				WHERE EXISTS (
					SELECT TOP (1) 'EXISTS'
					FROM [cte_i]
					WHERE [parentid] = [base].[id])
				UNION ALL
				SELECT [cte_ii].[id]
					,[cte_ii].[parentid]
					,[cte_ii].[localname]
					,JSON_MODIFY([cte_ii].[sub], CONCAT('strict $.', [cte_i].[localname]), JSON_QUERY([cte_i].[sub])) AS [sub]
					,[level] + (1) AS [level]
				FROM [cte_ii]
					JOIN [cte_i]
						ON [cte_i].[parentid] = [cte_ii].[id]
				WHERE JSON_MODIFY([cte_ii].[sub], CONCAT('strict $.', [cte_i].[localname]), JSON_QUERY([cte_i].[sub])) != [cte_ii].[sub])
			,[cte_iii] AS (
				SELECT *
					,ROW_NUMBER() OVER (PARTITION BY [id] ORDER BY [level] DESC) AS [order]
				FROM [cte_ii])
		UPDATE [base]
		SET [sub] = [cte_iii].[sub]
		FROM @base AS [base]
			JOIN [cte_iii]
				ON [cte_iii].[id] = [base].[id]
					AND [cte_iii].[order] = 1;

		DELETE [base]
		FROM @base AS [base]
			JOIN @sample AS [sample]
				ON [sample].[id] = [base].[id];

		DELETE FROM @sample;

	END

	SELECT TOP (1) @json_doc = [sub]
	FROM @base;

	SELECT @json_doc;

END
GO