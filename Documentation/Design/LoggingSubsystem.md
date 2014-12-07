# PGDCE Logging Subsystem Proposal #

As hinted in the class outline, I have a plan for implementing a logging system within PGDCE.  The proposal goes like this.

The system will consist of (initially at least) 3 key classes.

- TCELogger - This class will be the main interface between the application/library and the log
- TCEFileLoggingEngine - This class (a descendant of TCEBaseLoggingEngine) will implement a file based log.  It should handle the differences in platform (Windows vs. iOS vs. Android etc) and should ensure the file itself is protected from multithreaded access
- TCECodeSiteLoggingEngine - This class (a descendant of TCEBaseLoggingEngine) will implement a CodeSite based log.  At this time I believe this will be a WIndows only solution.
- TCEConsoleLoggingEngine - This class (a descendant of TCEBaseLoggingEngine) will implement an in-memory buffer to use in an in-game console.

The proposed interface to TCELogger is as follows.

- TCELogger.addEngine(TCEBaseLoggingEngine) - Add a logging engine to the system allowing simultaneous output to say a file and CodeSite
- TCELogger.removeEngine(TCEBaseLoggingEngine) - Remove the specificed logging engine from the system.  If the last logging engine is removed, an ECELoggerException is raised
- TCELogger.setLogLevel(TCELogEntryType) - Specifies which items are logged.  For example, if setLogLevel(leError) is called, only error messages are recorded, whereas if setLogLevele(leInfo) is called, informational, warning and error messages are recorded
-  TCELogger.setLogDetail(integer) - Specifies which items are logged.  For example, if setLogDetail(3) is called, only informational messages with a detail level of 3 or below will be logged
-  TCELogger.error(string) - Logs the message as an error
-  TCELogger.errorFmt(string,data) - Uses format to generate the message and logs it as an error
-  TCELogger.warning(string) - Logs the message as a warning
-  TCELogger.warningFmt(string,data) - Uses format to generate the message and logs it as a warning
-  TCELogger.info(integer,string) - Logs an informational message, level specified by the first paramater
-  TCELogger.infoFmt(integer,string,data) - Uses format to generate the message and logs it as an informational message, level specified by the first parameter

The engines will provide specific configuration relevant to them, so for example, the file engine will allow you to configure the output filename and the CodeSite engine will allow you to specify CodeSite configuration.  The engines will be in separate units so as to avoid issues if people don't have CodeSite (simply don't include the unit).

The logLevel and logDetail parameters... I'm open to thoughts on these, whether that's overkill, or even whether you may want to set those at the logging engine level, so for example, the file engine logs everything in great detail whilst say a TCEConsoleLoggingEngine may only log warnings and errors to an in-game console.