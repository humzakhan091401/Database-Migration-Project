USE [aspmsdev_db]
GO

/****** Object:  Table [dbo].[tbl_award]    Script Date: 4/22/2025 2:06:58 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tbl_award](
	[pk_award] [int] IDENTITY(1,1) NOT NULL,
	[fk_baa] [int] NULL,
	[proposal_no] [varchar](30) NULL,
	[status] [char](1) NULL,
	[baa] [varchar](50) NULL,
	[topic] [varchar](60) NULL,
	[title] [varchar](255) NULL,
	[typeAward] [varchar](5) NULL,
	[awardNumber] [varchar](30) NULL,
	[subtask] [char](2) NULL,
	[alias1] [varchar](20) NULL,
	[alias2] [varchar](20) NULL,
	[alias3] [varchar](20) NULL,
	[alias4] [varchar](20) NULL,
	[colorOfMoney] [char](3) NULL,
	[programElement] [varchar](15) NULL,
	[onr] [varchar](6) NULL,
	[dfas] [varchar](6) NULL,
	[duns] [varchar](12) NULL,
	[taxid] [varchar](20) NULL,
	[cage] [varchar](5) NULL,
	[initialAward] [datetime] NULL,
	[popStart] [datetime] NULL,
	[popEnd] [datetime] NULL,
	[opt1Start] [datetime] NULL,
	[opt1End] [datetime] NULL,
	[opt2Start] [datetime] NULL,
	[opt2End] [datetime] NULL,
	[fk_terms_Conditions] [int] NULL,
	[programYear] [char](4) NULL,
	[awardTitle] [varchar](255) NULL,
	[institution] [varchar](255) NULL,
	[city] [varchar](50) NULL,
	[state] [varchar](5) NULL,
	[thrustArea] [tinyint] NULL,
	[capabilityComponent] [varchar](255) NULL,
	[enterprise] [char](2) NULL,
	[patronTwo] [varchar](4) NULL,
	[patronThree] [char](4) NULL,
	[fundingEntity] [char](3) NULL,
	[cofunded] [char](3) NULL,
	[cofundDirectorate1] [char](3) NULL,
	[cofundDirectorate2] [char](3) NULL,
	[congressional] [tinyint] NULL,
	[pbd709] [tinyint] NULL,
	[dticNumber] [varchar](10) NULL,
	[animalUse] [tinyint] NULL,
	[humanUse] [tinyint] NULL,
	[hbcu] [tinyint] NULL,
	[indianControlled] [tinyint] NULL,
	[minority] [tinyint] NULL,
	[taxonomy] [varchar](200) NULL,
	[nanoTechnology] [tinyint] NULL,
	[dodPriority1] [varchar](100) NULL,
	[dodPriority2] [varchar](100) NULL,
	[dodPriority3] [varchar](100) NULL,
	[dateToBE] [datetime] NULL,
	[finalReportStatus] [varchar](50) NULL,
	[finalReportReceived] [varchar](50) NULL,
	[OPSECApproval] [varchar](50) NULL,
	[PARoutingNo] [varchar](50) NULL,
	[PAApproval] [varchar](50) NULL,
	[deleted] [tinyint] NULL,
	[deleteUser] [uniqueidentifier] NULL,
	[deleteDate] [datetime] NULL,
	[modifyUser] [varchar](50) NULL,
	[modifyDate] [datetime] NULL,
	[createUser] [varchar](50) NULL,
	[createDate] [datetime] NULL,
 CONSTRAINT [PK_tbl_award] PRIMARY KEY CLUSTERED 
(
	[pk_award] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


