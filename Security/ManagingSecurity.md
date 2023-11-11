# ADGroupMemberReport.ps1
Built upon Get-ADGroupMember to build out a detailed report by listing the AD group name, users within it, and recursing through the nested groups.

##Parameters

- `$SearchList`: Array of active directory groups.
- `$Export`: Triggers a .csv ouput file in addition to a console ouput table. Requires `$ExportDirectory`.
- `$ExportDirectory`: Used in conjunction with `$Export`, full file directory to export the `.csv`.
- `$Append`: Used with the export functionality, applies the results to an existing `.csv` file.
 
## Example

- AdminUsers:
  - Bob
  - Joe
  - Mary
- DevUsers: 
  - Richard
  - Jane
  - Paul
  - AdminUsers (Group)
 
`.\ADGroupMemberReport.ps1 -SearchList "AdminUsers", "DevUsers"`

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



