USE [SQLSourceControl]
GO
/****** Object:  StoredProcedure [dbo].[SVC_ExternalChangeCheck]    Script Date: 2017/02/15 09:19:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Bernie Groenewald
-- Create date: 20 July 2016
-- Description:	Initial
-- =============================================

ALTER PROCEDURE [dbo].[SVC_ExternalChangeCheck](@ObjectName varchar(255))
	
AS
BEGIN
	SET NOCOUNT ON;

	declare @HistoryID int
	declare @LCOHistoryID int
	declare @UserName varchar(50)
	declare @StatusDesc varchar(50)
	declare @AvailableForEdit varchar(1)
	declare @Comment varchar(2048)
	declare @HistoryDate datetime
	declare @DatabaseName varchar(50)
	declare @EmailAddress varchar(1024)
	declare @MailMessage varchar(4096)

	if exists(select HistoryID from SVC_ObjectHistory where ObjectName = @ObjectName)
	begin
		select @HistoryID = max(HistoryID)
		  from SVC_ObjectHistory 
		 where ObjectName = @ObjectName

		 --Can this object be edited?

		 select @AvailableForEdit =  OS.AvailableForEdit
		   from SVC_LU_ObjectStatus as OS inner join
			    SVC_ObjectHistory as OH on OS.ObjectStatusID = OH.ObjectStatusID
		  where OH.HistoryID = @HistoryID

		--If it is available, do nothing

		if @AvailableForEdit = 'Y'
		begin
			return
		end

		 --Get the last person that checked this object out

		 if exists(select HistoryID from SVC_ObjectHistory where ObjectName = @ObjectName and ObjectStatusID = 1) --1 - Check out for edit
		 begin
			select @LCOHistoryID = max(HistoryID)
			  from SVC_ObjectHistory 
			 where ObjectName = @ObjectName
			   and ObjectStatusID = 1

			select @UserName = UserName
			  from SVC_ObjectHistory
			 where HistoryID = @LCOHistoryID
		 end
		 else
		 begin
			-- Last check out person not found

			select @UserName = UserName
			  from SVC_ObjectHistory
			 where HistoryID = @HistoryID
		 end

		 select @StatusDesc = OS.ObjectStatusDesc, 
			    @HistoryDate = OH.HistoryDate, 
			    @DatabaseName = OH.DatabaseName, 
			    @Comment = OH.Comment
		   from SVC_LU_ObjectStatus as OS inner join
			    SVC_ObjectHistory as OH on OS.ObjectStatusID = OH.ObjectStatusID
		  where OH.HistoryID = @HistoryID

		select @EmailAddress = isnull(EmailAddress, '')
		  from SVC_SystemUser
		 where UserName = @UserName

		if @UserName <> ''
		begin
			begin try
				set @MailMessage = 'Attention: ' + @UserName + char(10) + char(13) + char(10) + char(13)

				set @MailMessage = @MailMessage + 'Object ' + @ObjectName + ' was modified in the production environment.' + char(10) + char(13)

				set @MailMessage = @MailMessage + 'Status description of this object: ' + @StatusDesc + char(10) + char(13)
				set @MailMessage = @MailMessage + 'Status date: ' + convert(varchar, @HistoryDate) + char(10) + char(13)
				set @MailMessage = @MailMessage + 'Database: ' + @DatabaseName + char(10) + char(13)
				set @MailMessage = @MailMessage + 'Comment: ' + @Comment + char(10) + char(13) + char(10) + char(13)
				set @MailMessage = @MailMessage + 'Please be sure to include these changes in your development object.' 

				insert into SVC_NotifyLog (UserName, ObjectName, DBName, LogMessage, LogDate)
				     select @UserName, @ObjectName, @DatabaseName, @MailMessage, getdate()

				exec Workflow..SPSendOutMail @EmailAddress, '', 'External Object Change', @MailMessage
			end try

			begin catch
				return
			end catch
		end
	end
END
