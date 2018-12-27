USE [OPERATIONS]
GO
/****** Object:  StoredProcedure [dbo].[usp_Arvada_WaterPipeTotals]    Script Date: 12/27/2018 10:58:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--swGravityMain
--swUnderDrain
--swIrrigationPipe
--swIrrigationDitch
--STATUS = 'Active' OR STATUS = 'Under Const'
ALTER procedure [dbo].[usp_Arvada_WaterPipeTotals]
        @EndDate datetime
/*
        
        exec usp_Arvada_WaterPipeTotals @enddate = '01/01/2018'

*/
as

set nocount on

set @EndDate = convert(Date, dateadd(day,1,@EndDate))

if object_id('tempdb.dbo.#data') is not null drop table #data
create table #data
(
        TableName varchar(50),
        ObjectId int,
        Material nvarchar(500),
        Diameter numeric(38,8),
        DIAMETERTEXT nvarchar(50),
        DiameterCombo nvarchar(50),
        ShapeLength float,
        MaterialText nvarchar(500),
        orderby int,
        rid int identity(1,1),
        MaterialDesc nvarchar(500)
)

create table #materials
(
        matCode varchar(50),
        matDesc varchar(500)
)

insert into #materials
(
        matCode,
        matDesc
)
select
        matcode,
        matDesc
from dbo.v_Arvada_PipeMaterials
 



declare 
                @IrrigationPipe float,
                @IrrigationDitch float

insert into #data
(
        TableName,
        ObjectId,
        Material,
        Diameter,
        DIAMETERTEXT,
        DiameterCombo,
        ShapeLength
)
select 
        'wMain' as TableName,
        ObjectID,
        isnull(MAterial,'Not Specified') ,
        DIAMETER,
        null as DIAMETERTEXT,
        isnull(convert(Varchar(50), convert(decimal(36,2), round(nullif(Diameter,-1),2))), '') as DiameterCombo,
        shape.STLength() as ShapeLength
from [OPS].wMain
where 
        status in ('Active' , 'Under Const')
        and (created_date is null or created_date <@enddate)
        and (DIAMETER >= 4)
union all
select 
        'wLateralLine' as TableName,
        ObjectID,
        isnull(MAterial,'Not Specified') ,
        DIAMETER,
        null as DIAMETERTEXT,
        isnull(convert(Varchar(50), convert(decimal(36,2), round(nullif(Diameter,-1),2))), '') as DiameterCombo,
        shape.STLength() as ShapeLength
from [OPS].wLAteralLine
where 
        status in ('Active' , 'Under Const')
        and (created_date is null or created_date < @enddate)
        and (DIAMETER >= 4)
         



--if we don't come close to having a number for a diameter, just null it out
update d
set DiameterCombo = null
from #data d
where isnumeric(diameterCombo) = 0
and diameterCombo not like '%[0-9]%'

update d
set DiameterCombo = 'OTHER'
from #data d
where 
(
        DIAMETER = -1
or DiameterCombo is null
)



update d
set MaterialText = material + ' - ' + DiameterCombo
from #data d
 
update d
set MaterialDesc = matDesc
from #data d
inner join #materials m
        on m.matCode = d.Material

update d
set orderby = b.orderby
from #data d
inner join
        (select
                        rank() over (partition by TableName, MaterialDesc order by case when DiameterCombo = 'OTHER' then 2 else 1 end, diameter) as orderby,
                        rid
         from #data
         ) as b
         on b.rid= d.rid
  

 


select 
        'Water Network' as TableName,
        'Water Network' as TableDesc,
        --TableName ,
        --case TableName
        --	when 'wLateralLine' then 'Service Lateral'
        --	when 'wMain' then 'Water Main' 
        --	else TableName end as TableDesc,
        --ObjectId ,
        --Material ,
        --Diameter ,
        --DIAMETERTEXT ,
        --DiameterCombo,
        sum(ShapeLength) as ShapeLength ,
        sum(ShapeLength / 5280.00) as LengthInMiles,
        max(orderby) as OrderBy,
        MaterialText,
        MaterialDesc as MaterialLongDesc
from #data 
group by  
        --TableName ,
        --case TableName
        --	when 'wLateralLine' then 'Service Lateral'
        --	when 'wMain' then 'Water Main' 
        --	else TableName end,
        MaterialText,
        MaterialDesc
                        
order by
        TableName,
        MaterialLongDesc, 
        ORderBy,
        MaterialText