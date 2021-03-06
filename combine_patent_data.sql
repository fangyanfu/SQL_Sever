/****** Script for SelectTopNRows command from SSMS  ******/

/****** we want to combine the data with its application date and relevant information. We have to use APPID as our key column to combine because a company might apply for a patent(patent family) 
  for several times(sub-patent), but they all belong to a single family. ******/

  select n.appln_id, n.BvDID, n.person_name, n.appln_title, n.year
  into development.dbo.fy_patent_data_20181104
  from(
  select s.*
  from (
  select *, row_number() over (partition by a.appln_id, a.BvDID, a.appln_title order by a.PatPublnNr) as group_index 
  from ( select f.appln_id, f.BvDID, f.person_name, f.PatPublnNr, p.appln_title, p.publn_date, year(p.publn_date) as year
  from [Patents062016].[dbo].[fg_patents_epde] as f
  left join [Patents062016].[dbo].[Patents] as p
  on f.appln_id = p.appln_id
  where f.appln_id is not null and p.appln_id is not null) as a
  ) as s
  where s.group_index = 1
  ) as n
  order by n.appln_id

/****** to count number of patent application, each company might have several rows ******/

  select l.*, r.pat_times
  from (select * from development.dbo.fy_patent_data_20181104 where BvDID is not null and year >= 1979) as l
  left join (select BvDID, count(BvDID) as pat_times from development.dbo.fy_patent_data_20181104 where BvDID is not null and year >= 1979 group by BvDID ) as r
  on l.BvDID = r.BvDID
  order by pat_times

 /******each company each row******/
  select n.BvDID, n.person_name, n.pat_times
  from(
  select s.*
  from (select *, row_number() over (partition by a.BvDID order by a.BvDID) as group_index
  from ( select l.*, r.pat_times
  from (select * from development.dbo.fy_patent_data_20181104 where BvDID is not null and year >= 1979) as l
  left join (select BvDID, count(BvDID) as pat_times from development.dbo.fy_patent_data_20181104 where BvDID is not null and year >= 1979 group by BvDID ) as r
  on l.BvDID = r.BvDID ) as a )
  as s
  where s.group_index = 1)
  as n
  order by n.pat_times

   /******combine with ma data******/
  select * 
  from (
  select l.*, r.pat_times,r.person_name
  from (select * from [development].[dbo].[fy_MA_final_data] where Number is not null) as l
  left join ( select n.BvDID, n.person_name, n.pat_times
				from(
				  select s.*
				  from (select *, row_number() over (partition by a.BvDID order by a.BvDID) as group_index
				  from ( select l.*, r.pat_times
				  from (select * from development.dbo.fy_patent_data_20181104 where BvDID is not null and year >= 1979) as l
				  left join (select BvDID, count(BvDID) as pat_times from development.dbo.fy_patent_data_20181104 where BvDID is not null and year >= 1979 group by BvDID ) as r
				  on l.BvDID = r.BvDID COLLATE SQL_Latin1_General_CP1_CI_AS) as a )
				  as s
				  where s.group_index = 1)
				  as n)  as r
	on l.Number = r.BvDID COLLATE SQL_Latin1_General_CP1_CI_AS
	) as n
	where n.pat_times is not null



  select  *
  from (select l.*, r.pat_times
		  from (select * from development.dbo.fy_patent_data_20181104 where BvDID is not null and year >= 1979) as l
		  left join (select BvDID, count(BvDID) as pat_times from development.dbo.fy_patent_data_20181104 where BvDID is not null and year >= 1979 group by BvDID ) as r
		  on l.BvDID = r.BvDID COLLATE SQL_Latin1_General_CP1_CI_AS
		 )  as l
  where l.BvDID COLLATE SQL_Latin1_General_CP1_CI_AS in (select Number from fy_MA_final_data where Number is not null)
  order by appln_id

  
  select distinct appln_id
  from [development].[dbo].[fy_pat_sci]

     /******to combine data with sci information. sci_pat means paper,0 means no paper
	 here we only include patent information that after 1979 and include in ma cases******/
  select *
  into fy_ma_pat_sci_data_20181105
  FROM 
  (SELECT*
  FROM (SELECT *, sci_pat = 1
  FROM [development].[dbo].[fy_patent_data_20181104] as p
  where p.appln_id in (select distinct appln_id
  from [development].[dbo].[fy_pat_sci])) as p
  UNION ( SELECT *, sci_pat = 0
  FROM [development].[dbo].[fy_patent_data_20181104] as p
  where p.appln_id not in (select distinct appln_id
  from [development].[dbo].[fy_pat_sci]))
  ) as a
  where a.BvDID COLLATE SQL_Latin1_General_CP1_CI_AS in (select distinct Number from [development].[dbo].[fy_ma_pat_data_without_null20181104])
  order by appln_id




/******to add new columns for target, vendors and acquirors to check if they apply for a patent after MA. each record stands for a MA record, 
with 1vendor/1acquiror/1target, the initial value is null for every records in each column******/
alter TABLE development.dbo.fy_MA_base_infor_20181107 
add target_pat_or_not INTEGER

alter TABLE development.dbo.fy_MA_base_infor_20181107 
add acquir_pat_or_not INTEGER

alter TABLE development.dbo.fy_MA_base_infor_20181107 
add vendor_pat_or_not INTEGER

/******to change value of target* column, if the target' bvdid is '' then value is 2, if it apply for a patent then value is 1, if not apply for a patent then
value is 0******/
UPDATE development.dbo.fy_MA_base_infor_20181107
SET target_pat_or_not = 1 where targetbvdidnumber COLLATE SQL_Latin1_General_CP1_CI_AS in (SELECT DISTINCT p.BvDID from [development].[dbo].[fy_patent_data_20181104] as p)

UPDATE development.dbo.fy_MA_base_infor_20181107
SET target_pat_or_not = 0 where targetbvdidnumber <> '' and targetbvdidnumber  COLLATE SQL_Latin1_General_CP1_CI_AS 
not in (SELECT DISTINCT p.BvDID from [development].[dbo].[fy_patent_data_20181104] as p where p.BvDID is not null)

UPDATE development.dbo.fy_MA_base_infor_20181107
SET acquir_pat_or_not = 2 where targetbvdidnumber =''


/******to change value of acquiror* column, if the target' bvdid is '' then value is 2, if it apply for a patent then value is 1, if not apply for a patent then
value is 0******/
UPDATE development.dbo.fy_MA_base_infor_20181107
SET acquir_pat_or_not = 1 where acquirorbvdidnumber COLLATE SQL_Latin1_General_CP1_CI_AS in (SELECT DISTINCT p.BvDID from [development].[dbo].[fy_patent_data_20181104] as p)

UPDATE development.dbo.fy_MA_base_infor_20181107
SET acquir_pat_or_not = 0 where acquirorbvdidnumber <> '' and acquirorbvdidnumber COLLATE SQL_Latin1_General_CP1_CI_AS 
not in (SELECT DISTINCT p.BvDID from [development].[dbo].[fy_patent_data_20181104] as p where p.BvDID is not null)

UPDATE development.dbo.fy_MA_base_infor_20181107
SET acquir_pat_or_not = 2  where acquirorbvdidnumber = ''

/******to change value of vendor* column, if the target' bvdid is '' then value is 2, if it apply for a patent then value is 1, if not apply for a patent then
value is 0******/
UPDATE development.dbo.fy_MA_base_infor_20181107
SET vendor_pat_or_not = 1 where vendorbvdidnumber COLLATE SQL_Latin1_General_CP1_CI_AS in (SELECT DISTINCT p.BvDID from [development].[dbo].[fy_patent_data_20181104] as p)

UPDATE development.dbo.fy_MA_base_infor_20181107
SET vendor_pat_or_not = 0 where vendorbvdidnumber <> '' and vendorbvdidnumber  COLLATE SQL_Latin1_General_CP1_CI_AS 
not in (SELECT DISTINCT p.BvDID from [development].[dbo].[fy_patent_data_20181104] as p where p.BvDID is not null)

UPDATE development.dbo.fy_MA_base_infor_20181107
SET vendor_pat_or_not = 2 where vendorbvdidnumber =''
