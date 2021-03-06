USE [SQLSourceControl]
GO
/****** Object:  StoredProcedure [dbo].[SVC_ServerGetServerDetailEncrypted]    Script Date: 2017/03/16 01:50:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Bernie Groenewald
-- Create date: 20 July 2016
-- Description:	Initial
-- =============================================

ALTER PROCEDURE [dbo].[SVC_ServerGetServerDetailEncrypted](@ServerAlias varchar(50), @UserID int)
AS
BEGIN
	SET NOCOUNT ON;

	declare @ServerAliasID int

	select @ServerAliasID = ServerAliasID
	  from SVC_LU_ServerAlias
	 where ServerAliasDesc = @ServerAlias

	if exists(select ServerID from [SVC_Server] where ServerAliasID = @ServerAliasID and UserID = @UserID)
	begin
		select S.ServerID, 
		       SA.ServerName, 
			   S.DBOwner, 
			   S.UserName, 
			   CONVERT(varchar, S.Password) AS Password, 
			   S.IntegratedSecurity, 
			   SR.ServerRoleDesc, 
			   SA.ServerRoleID, 
               S.ServerAliasID
          from SVC_Server as S inner join
               SVC_LU_ServerAlias as SA on S.ServerAliasID = SA.ServerAliasID inner join
               SVC_LU_ServerRole as SR on SA.ServerRoleID = SR.ServerRoleID
		 where S.ServerAliasID = @ServerAliasID
		   and S.UserID = @UserID
	end
	else
	begin
		select '' as ServerID, 
		       '' as ServerName, 
			   '' as DBOwner, 
			   '' as UserName, 
			   '' as Password,
			   '' as IntegratedSecurity,
			   '' as ServerRoleDesc,
			   0 as ServerRoleID,
			   0 as ServerAliasID
	end
END

