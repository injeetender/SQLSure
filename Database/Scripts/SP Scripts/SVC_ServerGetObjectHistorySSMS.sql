USE [SQLSourceControl]
GO
/****** Object:  StoredProcedure [dbo].[SVC_ServerGetObjectHistorySSMS]    Script Date: 2017/03/16 01:42:17 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Bernie Groenewald
-- Create date: 20 July 2016
-- Description:	Initial
-- =============================================

ALTER PROCEDURE [dbo].[SVC_ServerGetObjectHistorySSMS](@ServerName varchar(255), @UserID int)
	
AS
BEGIN
	SET NOCOUNT ON;

	declare @ServerGroupID int
	declare @ServerAliasID int
	declare @UserName varchar(50)
	declare @CheckOutUserName varchar(50)
	declare @Database varchar(255)
	declare @Name varchar(255)

	create table #TmpSet ([Status] varchar(255), 
	                       [Date] varchar(50), 
						   [User] varchar(50), 
						   [Name] varchar(255), 
						   [Database] varchar(255), 
						   [Comment] varchar(1024), 
						   [Alias] varchar(255), 
						   [Server] varchar(255),
						   [AvailableForEdit] varchar(1),
						   [PartOfDevCycle] varchar(1),
						   [CheckOutUser] varchar(50),
						   [StatusID] int)

	select @ServerAliasID = S.ServerAliasID
	  from SVC_Server as S inner join
           SVC_LU_ServerAlias as SA on S.ServerAliasID = SA.ServerAliasID
	 where SA.ServerName = @ServerName
	   and UserID = @UserID

	select @ServerGroupID = ServerGroupID
	  from SVC_LU_ServerAlias
	 where ServerAliasID = @ServerAliasID;

	with testRowNumber as ( select OS.ObjectStatusDesc as [Status], 
								   OH.HistoryDate as [Date], 
								   OH.UserName as [User], 
								   OH.ObjectName as [Name], 
								   OH.DatabaseName as [Database], 
								   OH.Comment as [Comment], 
								   LSA.ServerAliasDesc as [Alias], 
								   LSA.ServerName as [Server],
								   OS.PartOfDevCycle as [PartOfDevCycle],
								   OS.AvailableForEdit,
								   row_number() over (partition by OH.ObjectName, OH.DatabaseName order by OH.HistoryDate desc) as RowNum,
								   OH.ObjectStatusID as [StatusID]
							  from SVC_LU_ObjectStatus as OS inner join
								   SVC_ObjectHistory as OH on OS.ObjectStatusID = OH.ObjectStatusID inner join
								   SVC_Server as S on OH.ServerID = S.ServerID inner join
								   SVC_LU_ServerAlias as LSA on S.ServerAliasID = LSA.ServerAliasID
							 where LSA.ServerGroupID = @ServerGroupID)
		   
	 
	insert into #TmpSet ([Status], [Date], [User], [Name], [Database], [Comment], [Alias], [Server], [AvailableForEdit], [PartOfDevCycle], [CheckOutUser], [StatusID])
	select [Status], [Date], [User], [Name], [Database], [Comment], [Alias], [Server], [AvailableForEdit], [PartOfDevCycle], '', [StatusID]
	from testRowNumber
	where RowNum = 1
	  and AvailableForEdit = 'N'
	order by [Name], [Database]

	declare RowCur cursor for
		  select [User], [Name], [Database]
		    from #TmpSet
	
	open RowCur

	fetch next from RowCur into @UserName, @Name, @Database
		
	while (@@fetch_status <> -1)
	begin
		set @CheckOutUserName = ''

		select top 1 @CheckOutUserName = isnull(UserName, '')
		        from SVC_ObjectHistory
		       where DatabaseName = @Database
		         and ObjectName = @Name
                 and ObjectStatusID = 1
            order by HistoryID desc

		if @CheckOutUserName <> ''
		begin
			update #TmpSet
			   set CheckOutUser = @CheckOutUserName
			 where [Database] = @Database
		       and [Name] = @Name
		end

		fetch next from RowCur into @UserName, @Name, @Database
	end

	close RowCur
	deallocate RowCur

	select [Status], [Date], [User], [Name], [Database], [Comment], [Alias], [Server], [AvailableForEdit], [PartOfDevCycle], [CheckOutUser], [StatusID]
	  from #TmpSet

	drop table #TmpSet
END
