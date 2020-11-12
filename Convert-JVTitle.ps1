function Convert-JVTitle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [PSObject]$Files,

        [Parameter()]
        [Switch]$Strict,

        [Parameter()]
        [Boolean]$RegexEnabled,

        [Parameter()]
        [String]$RegexString,

        [Parameter()]
        [Int]$RegexIdMatch,

        [Parameter()]
        [Int]$RegexPtMatch
    )

    process {
        $dataObject = @()
        $fileBaseNameUpper = @()
        $fileBaseNameUpperCleaned = @()
        $fileBaseNameHyphen = $null
        $fileP1, $fileP2, $fileP3, $fileP4 = @()
        #manual change regex first
        if ($Files -match '[A-Za-z]{3,}-[0-9]{3,}') {
                    $fileBaseNameOriginal = $matches[0]
                } else {
                
            $fileBaseNameOriginal = @($Files.BaseName)
        }
        # Unwanted strings in files to remove
        $RemoveStrings = @(
            # Prefixes
            '[\u3040-\u309f]|[\u30a0-\u30ff]|[\uff66-\uff9f]|[\u4e00-\u9faf]',
            '[@|-|_]?[a-zA-Z0-9]+(\.com|\.net|\.tk)[_|-]?',
            '^_'
            '^[0-9]{4}',
            '069-3XPLANET-',
            'Watch18plus-',
            '\[(.*?)\]',
            'FHD-',
            'FHD_',
            'fhd',
            'Watch ',
            # Suffixes (obsolete(?))
            '-h264',
            '-AV',
            '_www.avcens.download'
            '_JAV.1399.net',
            '_JAV-Video.net',
            '-VIDEOAV.NET',
            '-JAVTEG.NET',
            '.hevc.',
            '.javaddiction'
            'SmallJAV',
            ' AVFUL.TK',
            ' INCESTING.TK',
            'javnasty.tk',
            ' javhd21.com',
            ' avfullhd.tk',
            '.1080p',
            '.720p',
            '.480p',
            '-HD',
            'wmv',
            '.wmv',
            'avi',
            '.avi',
            'mp4',
            '.mp4',
            '_',
            '^-',
            '^2  S 17    ',
            '^2  S  AV     '
        )

        if ($RegexEnabled) {
            foreach ($file in $FileBaseNameOriginal) {
                
                $fileBaseNameUpper += $file.ToUpper()
                
            }

            $index = 0
            foreach ($file in $fileBaseNameUpper) {
                try {
                    $id = ($file | Select-String $RegexString).Matches.Groups[$RegexIdMatch].Value
                    $partNum = ($file | Select-String $RegexString).Matches.Groups[$RegexPtMatch].Value

                    # If ID#### and there's no hypen, subsequent searches will fail
                    if($id -match '^([a-z]+)(\d+)$') {
                        $id = $Matches[1] + "-" + ($Matches[2] -replace '^0{1,5}', '').PadLeft(3, '0')
                    }
                } catch {
                    Write-JVLog -Write:$script:JVLogWrite -LogPath $script:JVLogPath -WriteLevel $script:JVLogWriteLevel -Level Debug -Message "File [$file] not matched by regex"
                    break
                }
                if ($fileBaseNameUpper -eq 1) {
                    if ($partNum -ne '') {
                        $fileBaseNameUpper = "$id-PT$PartNum"
                    } elseif ($id -ne '') {
                        $fileBaseNameUpper = "$id"
                    } else {
                        $fileBaseNameUpper = $file
                    }
                } else {
                    if ($partNum -ne '') {
                        $fileBaseNameUpper[$index] = "$id-PT$PartNum"
                    } elseif ($id -ne '') {
                        $fileBaseNameUpper[$index] = "$id"
                    } else {
                        $fileBaseNameUpper[$index] = $file
                    }
                }
                $index++
            }
        } else {
            # Iterate through each value in $RemoveStrings and replace from $FileBaseNameOriginal
            foreach ($string in $RemoveStrings) {
                if ($string -eq '_') {
                    $fileBaseNameOriginal = $fileBaseNameOriginal -replace $string, '-'
                } else {
                    $fileBaseNameOriginal = $fileBaseNameOriginal -replace $string, ''
                    
                }
            }

            foreach ($file in $FileBaseNameOriginal) {
                $fileBaseNameUpper += $file.ToUpper()
            }

            # Iterate through each file in $Files to add hypen(-) between title and ID if not exists
            $counter = -1
            foreach ($file in $fileBaseNameUpper) {
                if ($file -match '^t28' -or $file -match '^t-28' -or $file -match '^r18' -or $file -match '^r-18') {
                    if ($file -match '^t28' -or $file -match '^t-28') {
                        $file = $file -replace 't-28', 't28'
                        if ($file -notmatch '-') {
                            $file = ($file -split 't28') -join 'T28-'
                            $fileBaseNameUpper[$counter] = $file
                        }
                    } elseif ($file -match '^r18' -or $file -match '^r-18') {
                        $file = $file -replace 'r-18', 'r18'
                        if ($file -notmatch '-') {
                            $file = ($file -split 'r18') -join 'R18-'
                            $fileBaseNameUpper[$counter] = $file
                        }
                        
                    } 
                    
                    else {
                        $fileBaseNameUpper[$counter] = $file
                    }
                } else {
                    # Iterate through file name length
                    for ($x = 0; $x -lt $file.Length; $x++) {
                        # Match if an alphabetical character index is next to a numerical index
                        if ($file[$x] -match '^[a-z]*$' -and $file[$x + 1] -match '^[0-9]$') {
                            # Write modified filename to $fileBaseNameHyphen, inserting a '-' at the specified
                            # index between the alphabetical and numerical character, and appending extension
                            $fileBaseNameHyphen = ($file.Insert($x + 1, '-'))
                            break
                        }
                    }
                    # Get index if file changed
                    $counter++
                    # Rename changed files
                    if ($null -ne $fileBaseNameHyphen) {
                        $fileBaseNameUpper[$counter] = $fileBaseNameHyphen
                    }
                    $fileBaseNameHyphen = $null
                }
            }
        }

        # Clean any trailing text if not removed by $RemoveStrings
        for ($x = 0; $x -lt $fileBaseNameUpper.Length; $x++) {
            $filePartNumber = $null
            # Match ID-###A, ID###B, etc.
            # Match ID-###-A, ID-###-B, etc.
            # Match ID-### - A, ID-### - B, etc.
            if ($fileBaseNameUpper[$x] -match "[-][0-9]{1,6}Z?E?R?\s?[-]?\s?[A-D]$") {
                $fileP1, $fileP2, $fileP3 = $fileBaseNameUpper[$x] -split "([-][0-9]{1,6}Z?E?)"
                $fileBaseNameUpperCleaned += $fileP1 + "-" + (($fileP2 -replace '-', '') -replace '^0{1,5}', '').PadLeft(3, '0')
                $fileP3 = ($fileP3 -replace '-', '').Trim()
                $asciiP3 = [int][char]$fileP3
                if ($asciiP3 -gt 64 -and $asciiP3 -lt 69) {
                    $filePartNumber = $asciiP3 - 64
                }
            }
            <#
                #Match ID-###-A, ID-###-B, etc.
                elseif ($fileBaseNameUpper[$x] -match "[-][0-9]{1,6}[-][a-iA-I]$") {
                    Write-JVLog -Write:$script:JVLogWrite -LogPath $script:JVLogPath -WriteLevel $script:JVLogWriteLevel -Level Debug -Message "Match 3"
                    $fileP1, $fileP2, $fileP3, $fileP4 = $fileBaseNameUpper[$x] -split "([-][0-9]{1,6})[-]([a-zA-Z])"
                    $fileBaseNameUpperCleaned += $fileP1 + $fileP2 + $fileP3
                }
                #>
            # Match ID-###-1, ID-###-2, etc.
            # Match ID-###-01, ID-###-02, etc.
            # Match ID-###-001, ID-###-002, etc.
            # Match ID-###-pt1, ID-###-pt2, etc.
            # Match ID-### - pt1, ID-### - pt2, etc.
            # Match ID-###-part1, ID-###-part2, etc.
            # Match ID-### - part1, ID ### - part2, etc.
            # Match ID-###-cd1, ID-###-cd2, etc.
            # Match ID-### - cd1, ID-### - cd2, etc.
            elseif ($fileBaseNameUpper[$x] -match "[-][0-9]{1,6}Z?E?R?\s?[-]\s?(cd|part|pt)?[-]?\d{1,3}") {
                $fileP1, $fileP2, $fileP3 = $fileBaseNameUpper[$x] -split "([-][0-9]{1,6}Z?E?\s?[-])"
                $fileBaseNameUpperCleaned += $fileP1 + "-" + (($fileP2 -replace '-', '') -replace '^0{1,5}', '').Trim().PadLeft(3, '0')
                $filePartNum = ((($fileP3.Trim() -replace '-', '') -replace '^0{1,5}', '') -replace '(cd|part|pt)', '')
                $filePartNumber = [int]$filePartNum
            }

            # Match everything else
            else {
                $fileP1, $fileP2, $fileP3 = $fileBaseNameUpper[$x] -split "([-][0-9]{1,6})"
                if ($fileP3 -match '^[ZER]') {
                    $fileBaseNameUpperCleaned += $fileP1 + $fileP2 + $fileP3
                } else {
                    $fileBaseNameUpperCleaned += $fileP1 + $fileP2
                }
            }
            <#             if ($fileBaseNameUpper[$x] -match '([a-zA-Z|tT28]+-\d+z{0,1}Z{0,1}e{0,1}E{0,1})') {
                $movieId = $fileBaseNameUpper[$x]
                $splitId = $fileBaseNameUpper[$x] -split '-'
                $contentId = $splitId[0] + $splitId[1].PadLeft(5, '0')
            } else {
                $movieId = ($fileBaseNameUpper[$x] -split '\d', 3 | Where-Object { $_ -ne '' }) -join '-'
                $contentId = $fileBaseNameUpper[$x]
            } #>


            if ($fileBaseNameUpper[$x] -match '(([a-zA-Z|tT28|rR18]+)-(\d+z{0,1}Z{0,1}e{0,1}E{0,1}))') {
                $movieId = $fileBaseNameUpperCleaned[$x]
                $splitId = $fileBaseNameUpperCleaned[$x] -split '-'
                if (($splitId[1])[-1] -match '\D') {
                    $appendChar = ($splitId[1])[-1]
                    $splitId[1] = $splitId[1] -replace '\D', ''
                }
                $contentId = $splitId[0] + $splitId[1].PadLeft(5, '0') + $appendChar
                $contentId = $contentId.Trim()
            } 
          
            
            elseif ($RegexEnabled) {
                $movieId = $fileBaseNameUpperCleaned[$x]
                $contentId = $fileBaseNameUpperCleaned[$x]
            } else {
                $movieId = ($fileBaseNameUpperCleaned[$x] -split '\d', 3 | Where-Object { $_ -ne '' }) -join '-'
                $contentId = $fileBaseNameUpperCleaned[$x]
            }

            if ($Files.Count -eq '1') {
                $originalFileName = $Files.Name
                $originalBaseName = $Files.BaseName
                $originalDirectory = $Files.Directory
                $fileExtension = $Files.Extension
                $filePartNumber = if ($RegexEnabled) { $partNum } else { $filePartNumber }
            } else {
                $originalFileName = $Files.Name[$x]
                $originalBaseName = $Files.BaseName[$x]
                $originalDirectory = $Files.Directory[$x]
                $fileExtension = $Files.Extension[$x]
                $filePartNumber = if ($RegexEnabled) { $partNum } else { $filePartNumber }
            }

            if ($Strict.IsPresent) {
                $dataObject += [PSCustomObject]@{
                    Id         = $originalBaseName
                    ContentId  = $contentId
                    FileName   = $originalFileName
                    BaseName   = $originalBaseName
                    Directory  = $originalDirectory
                    FullName   = if ($Files.Count -eq 1) { $Files.FullName } else { $Files.fullname[$x] }
                    Extension  = $fileExtension
                    Length     = [Math]::Round($Files.Length[$x] / 1MB, 2)
                    PartNumber = $filePartNumber
                }
            } else {
                $dataObject += [PSCustomObject]@{
                    Id         = $movieId
                    ContentId  = $contentId
                    FileName   = $originalFileName
                    BaseName   = $originalBaseName
                    Directory  = $originalDirectory
                    FullName   = if ($Files.Count -eq 1) { $Files.FullName } else { $Files.fullname[$x] }
                    Extension  = $fileExtension
                    Length     = [Math]::Round($Files.Length[$x] / 1MB, 2)
                    PartNumber = $filePartNumber
                }
            }
        }
        Write-Output $dataObject
    }
}
