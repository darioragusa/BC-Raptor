$objectNo = 50101;
$objectName = 'BCR Raptor Ext'
$fileName = 'Cod50101.BcRaptorExt.al'
$fileFullName =  ".\src\codeunit\$($fileName)"
$cleanVarNameRegex = '(\s|"|-|\.|\/|\\|\(|\)|\?|&|'')'
$invalidTables = '^(1995|3712|3902|5557|8889|8912|9010|9067|9701|9987|9989|9990|2000000130|2000000159|2000000170|2000000204|2000000206|2000000244|2000000265)$'

Get-ChildItem -Path '.\.alpackages' -Filter '*.app' | ForEach-Object {
	& ${env:ProgramFiles}\7-Zip\7z.exe x $_.FullName "-o$($_.DirectoryName)/$($_.Basename)" 'SymbolReference.json' -y
}

if (Test-Path $fileFullName) {
	Remove-Item $fileFullName -verbose
}

@"
codeunit $($objectNo) "$($objectName)"
{
"@ >> $fileFullName

$totalFields = 0;
function Find-Controls($json, $pageName, $sourceTable) {
	if ([bool]($json.PSobject.Properties.name -match "Controls")) {
		$json.Controls | Foreach-Object {
			Find-Controls $_ $pageName $sourceTable
		}
	}
	if (![bool]($json.PSobject.Properties.name -match "Kind")) { return }
	if ($json.Kind -ne 8) { return }
	if ($_.Properties.Name -contains "ObsoleteState") { Write-Host -ForegroundColor Red "  - ""$($_.Name)"""; return }
	$notEditable = $false
	$notRec = $false
	$sourceExpr = ''
	if ($_.Properties.Name -contains "Editable") { $notEditable = $_.Properties.Where({$_.Name -eq "Editable"}).Value -ne 'False' }
	if ($notEditable) { Write-Host -ForegroundColor Red "  - ""$($_.Name)"""; return }
	if ($_.Properties.Name -contains "SourceExpression") {
		$sourceExpr = $_.Properties.Where({$_.Name -eq "SourceExpression"}).Value;
		$notRec = $sourceExpr -notmatch '^Rec\..*[^)]$'
	}
	if ($notRec) { Write-Host -ForegroundColor Red "  - ""$($_.Name)"""; return }
	if ($json.TypeDefinition.Name -notmatch '^(Code|Text).*') { Write-Host -ForegroundColor Red "  - ""$($_.Name)"""; return	}
	$Global:totalFields++;
	Write-Host -ForegroundColor Green "  - ""$($_.Name)"""
@"
    [EventSubscriber(ObjectType::Page, Page::"$($pageName)", 'OnBeforeValidateEvent', '$($_.Name -replace "'", "''")', false, false)]
    local procedure OnBeforeValidateEvent_$($pageName -replace $Global:cleanVarNameRegex, '')_$($_.Name -replace $Global:cleanVarNameRegex, '')(var Rec: Record $($sourceTable))
    begin
        Raptor.Roar($($sourceExpr));
    end;
"@ >> $fileFullName 
}

function Find-Pages($json, $ns) {
	if ([bool]($json.PSobject.Properties.name -match "Namespaces")) {
		$json.Namespaces | Foreach-Object {
			Write-Host "Namespace: $($ns)$($_.Name)"
			Find-Pages $_ "$($ns)$($_.Name)."
		}
	}
	if ([bool]($json.PSobject.Properties.name -match "Pages")) {
		$json.Pages | Foreach-Object {
			$obsolete = $_.Properties.Name -contains "ObsoleteState"
			$notEditable = $false
			$modifyAllowed = $true
			if ($_.Properties.Name -contains "Editable") { $notEditable = $_.Properties.Where({$_.Name -eq "Editable"}).Value -ne 'False'}
			if ($_.Properties.Name -contains "ModifyAllowed") { $modifyAllowed = $_.Properties.Where({$_.Name -eq "ModifyAllowed"}).Value -eq 'True' }
			if ($obsolete -or $notEditable -or !$modifyAllowed) { Write-Host -ForegroundColor DarkRed "  Page $($_.Id) ""$($_.Name)"""; return }
			$sourceTable = ''
			if ($_.Properties.Name -contains "SourceTable") { $sourceTable = $_.Properties.Where({$_.Name -eq "SourceTable"}).Value }
			if ($sourceTable -match $Global:invalidTables) { Write-Host -ForegroundColor DarkRed "  Page $($_.Id) ""$($_.Name)"""; return }
			Write-Host -ForegroundColor Green "  Page $($_.Id) ""$($_.Name)"""
			Find-Controls $_ "$($_.Name)" $sourceTable
		}
	}
}

Get-ChildItem -Path '.\.alpackages' -Recurse -Filter 'SymbolReference.json' | ForEach-Object {
	Write-Output $_.FullName
	$json = Get-Content $_.FullName -Raw | ConvertFrom-Json
	Find-Pages $json ''
}

@"
    var
        Raptor: Codeunit "BCR Raptor";
}
"@ >> $fileFullName

Write-Host -ForegroundColor Green "Fields found: $($totalFields)"

Get-ChildItem -Path '.\.alpackages' -Filter '*.app' | ForEach-Object {
	Remove-Item -Recurse "$($_.DirectoryName)/$($_.Basename)"
}

# powershell -File "run.ps1"