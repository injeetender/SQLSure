USE [SQLSourceControl]
GO
/****** Object:  StoredProcedure [dbo].[SVC_ServerGetServers]    Script Date: 2017/03/16 10:31:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Bernie Groenewald
-- Create date: 20 July 2016
-- Description:	Initial
-- =============================================

ALTER PROCEDURE [dbo].[SVC_ServerGetServers] (@UserID int)
AS
BEGIN
	SET NOCOUNT ON;

	declare @PassPhrase nvarchar(128)

	set @PassPhrase = ''

	exec SVC_SecurityKey @PassPhrase = @PassPhrase output


	select S.ServerID, 
	       SL.ServerAliasDesc, 
		   SL.ServerName, 
		   S.UserName, 
		   convert(varchar, DecryptByPassPhrase(@PassPhrase, S.Password)) as [Password],
		   S.ServerActive, 
		   S.CreateDate, 
		   S.IntegratedSecurity, 
		   SL.ServerAliasID, 
		   SG.ServerGroupDesc, 
           SR.ServerRoleDesc
      from SVC_LU_ServerAlias as SL inner join
           SVC_Server as S on SL.ServerAliasID = S.ServerAliasID inner join
           SVC_LU_ServerGroup as SG on SL.ServerGroupID = SG.ServerGroupID inner join
           SVC_LU_ServerRole as SR on SL.ServerRoleID = SR.ServerRoleID
	 where S.UserID = @UserID
  order by SL.ServerGroupID, SL.ReleaseOrder
END
