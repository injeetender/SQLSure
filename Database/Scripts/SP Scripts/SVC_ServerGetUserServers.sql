USE [SQLSourceControl]
GO
/****** Object:  StoredProcedure [dbo].[SVC_ServerGetUserServers]    Script Date: 2017/03/17 08:32:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Bernie Groenewald
-- Create date: 20 July 2016
-- Description:	Initial
-- =============================================

ALTER PROCEDURE [dbo].[SVC_ServerGetUserServers] (@UserID int)
AS
BEGIN
	SET NOCOUNT ON;

	select S.ServerID,
		   SA.ServerAliasDesc, 
	       SA.ServerName, 
		   S.UserName, 
		   isnull(S.Password, convert(varbinary, '')) as [Password],
		   S.ServerActive, 
		   S.CreateDate, 
		   S.IntegratedSecurity, 
           SA.ServerAliasID, 
		   SG.ServerGroupDesc, 
		   SR.ServerRoleDesc
      from SVC_LU_ServerAlias as SA inner join
           SVC_LU_ServerGroup as SG ON SA.ServerGroupID = SG.ServerGroupID inner join
           SVC_Server as S ON SA.ServerAliasID = S.ServerAliasID inner join
           SVC_LU_ServerRole as SR ON SA.ServerRoleID = SR.ServerRoleID
     where S.UserID = @UserID
  order by SA.ServerGroupID, SA.ReleaseOrder


END
