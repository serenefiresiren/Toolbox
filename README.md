# Toolbox
Miscellaneous scripts to work with and/or manage AD, SQL Security, DDL, DML, and so on either through generic PowerShell, DBATools, or T-SQL.

# Security
##ADGroupMemberReport.ps1
Built upon Get-ADGroupMember to build out a report detailing by listing the AD group name, users within it, and recursing through the nested groups.
 
Active Directory Sample Groups
---AdminUsers:
------- Bob
------- Joe
------- Mary

---DevUsers: 
------- Richard
------- Jane
------- Paul
------- AdminUsers (Group)

``.\ADGroupMemberReport.ps1 -SearchList "AdminUsers", "DevUsers"`` 

Output

|ParentGroupName|ObjectClass|SamAccountName|
|---|---|---|
|AdminUsers|Search||
|AdminUsers|user|Bob|
|AdminUsers|user|Joe|
|AdminUsers|user|Mary|
|DevUsers|Search||
|DevUsers|user|Richard|
|DevUsers|user|Jane|
|DevUsers|user|Paul|
|AdminUsers|user|Bob|
|AdminUsers|user|Joe|
|AdminUsers|user|Mary|



