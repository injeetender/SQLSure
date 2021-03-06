USE [SQLSourceControl]
GO
/****** Object:  StoredProcedure [dbo].[SVC_ServerIsDevServer]    Script Date: 2017/03/16 10:59:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Bernie Groenewald
-- Create date: 20 July 2016
-- Description:	Initial
-- =============================================

ALTER PROCEDURE [dbo].[SVC_ServerIsDevServer]( @ServerAlias varchar(50),
                                                @UserID int)
AS
BEGIN
	SET NOCOUNT ON;

	if exists(select LSR.ServerRoleDesc
			    from SVC_LU_ServerAlias as LSA inner join
                     SVC_Server as S on LSA.ServerAliasID = S.ServerAliasID inner join
                     SVC_LU_ServerRole as LSR on LSA.ServerRoleID = LSR.ServerRoleID
			   where LSA.ServerAliasDesc = @ServerAlias
			     and S.UserID = @UserID
				 and LSR.ServerRoleDesc = 'Development')
	begin
		select 'Y' as IsDevServer
	end
	else
	begin
		select 'N' as IsDevServer
	end
END
