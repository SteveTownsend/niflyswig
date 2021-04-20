foreach ($file in Get-ChildItem | Select-String -pattern "public static readonly string BlockName" | Select-Object -Unique Path) {
  $out = (Split-Path -LeafBase $file.Path);
  $code = $code + "if (objType == " + $out + ".BlockName)`r`n{`r`n    ret = new " + $out + "(cPtr, owner);`r`n} else "} $code | Out-File codegen/code.txt
