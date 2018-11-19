$version = $PSVersionTable
Write-Host -ForegroundColor Red "Ensure that your Powershell Version is greater than 5.1"
Write-Host -ForegroundColor Green "Your Powershell version:  " + $version.PSVersion.ToString()
$shares = Read-Host -prompt "P Drive Share Path"
$outputPath = Read-Host -prompt "Full path and filename to output HTML file"
function letsGo(){
$htmlStuff = @'
<html>
<head>
<style>
/* Remove default bullets */
ul, #myUL {
  list-style-type: none;
}

/* Remove margins and padding from the parent ul */
#myUL {
  margin: 0;
  padding: 0;
}

/* Style the caret/arrow */
.caret {
  cursor: pointer; 
  user-select: none; /* Prevent text selection */
}

/* Create the caret/arrow with a unicode, and style it */
.caret::before {
  content: "\25B6";
  color: black;
  display: inline-block;
  margin-right: 6px;
  transform: rotate(90deg);
}

/* Rotate the caret/arrow icon when clicked on (using JavaScript) */
.caret-down::before {
    content: "\25B6";
    color: black;
    display: inline-block;
    margin-right: 6px;
    transform: rotate(270deg);
}

/* Hide the nested list */
.nested {
  display: block;
}

/* Show the nested list when the user clicks on the caret/arrow (with JavaScript) */
.active {
  display: none;
}
</style>
</head>
<body>
<ul id="myUL">
'@
$javaScriptTag = @'
</ul>
<script>
var toggler = document.getElementsByClassName("caret");
var i;

for (i = 0; i < toggler.length; i++) {
toggler[i].addEventListener("click", function() {
    this.parentElement.querySelector(".nested").classList.toggle("active");
    this.classList.toggle("caret-down");
});
}
</script>
'@
    Write-Output $htmlStuff

    resolveTop $safeRoot
    Write-Output $javaScriptTag
    Write-Output "</body></html>"
}
# Sets list structure for parent folders
function setParentStructure($parentFolder){
    Write-Output "<li><span class='caret'>$parentFolder</span>"
    getAcl $parentFolder
    Write-Output "<ul class='nested'>"
}
# Parent list items must enclose the entirety of the nested unorgnized lists this closes that structure
function setCloseParentStructure(){
    Write-Output "</ul>"
    Write-Output "</li>"
}
# Folders with no children are set as singular list items
function setSingleStructure($singleFolder){
    Write-Output "<li>"
    Write-Output $singleFolder.Name
    getAcl $singleFolder
    Write-Output "</li>"
}

# Determines if folder has children, sets structure for both single and parent folders
function iterateStructure($folders){
    $childFolders = Get-ChildItem -LiteralPath $folders.FullName -Directory
    if($childFolders.Length -gt 0){
        setParentStructure $folders
        resolveChildren $childFolders
        setCloseParentStructure
    }else{
        setSingleStructure $folders
    }
}
# Resolves top most folder and kicks off the iterations
function resolveTop($topFolderPath){
    $topFolder = Get-Item $topFolderPath
    iterateStructure $topFolder
}

# Iterates through item collection for each child item
function resolveChildren($folderCollection){
    foreach($childFolder in $folderCollection){
        iterateStructure $childFolder
    }
}

#Checks the ACL and writes them out as unorgnized lists
function getAcl($aclFolder){
    $theAcl = Get-Acl -LiteralPath $aclFolder.FullName
    if($theAcl -eq $null){
        $theAcl = Get-Acl -Path ([Management.Automation.WildcardPattern]::Escape($aclFolder.FullName))
    }
    Write-Output "<ul><ul>"
    try{
    $inherit = $theAcl.access.isinherited[0]
    }catch{
        Write-Output "error"
    }
        #if ( $inherit -eq $false -or $space -eq "") {
        if ( $inherit -eq $false){   
            foreach ($access in $theAcl.access) {
                Write-Output "<li> User:  $($access.identityreference) Rights:  $($access.FileSystemRights)</li>"
            }
        }else{
                Write-Output "<li> Inherited from Parent</li>"
        }
    Write-Output "</ul></ul>"
}

# Add suffix to use Get-Item and Get-ChildItem on file paths greater the 256 charicters
$uncCheck = $shares.Substring(0,2)
if($uncCheck -eq "\\"){
    $safeRoot = $shares.Replace("\\","\\?\UNC\")
}else{
    $safeRoot = "\\?\$shares"
}
letsGo | Out-File $outputPath
