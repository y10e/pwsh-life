$DebugPreference = "Continue"
$RANDOM = New-Object -TypeName 'Random'
$Live = "※"
$Dead = "　"

function Make-Board(){
  1..$height | % { $script:CURRENT += ( (Get-Line).ToString() ); }
  $script:CURRENT += "GENERATION:  $GENERATION"
  $RUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates -ArgumentList  $width, $height
}

function Get-Line(){
   1..$width | % { $line += (Get-Cell) }
   return $line
}

function Get-Cell(){
   if( $RANDOM.NextDouble() -lt 0.5){ 
        $cell = $script:Dead
   }else{
        $cell = $script:Live
   }
   return $cell
}

function Get-Key(){
  while($RUI.KeyAvailable){
    $t = $RUI.ReadKey('NoEcho,IncludeKeyDown,IncludeKeyUp')
    if($key.KeyDown)
    {
        return $true
    }
  }
}

function Display-Board(){
  $RUI.SetBufferContents($ZERO, $RUI.NewBufferCellArray($script:CURRENT, 'White', 'Black'))
  #Get-ScreenCapture $script:GENERATION　#世代ごとの画面キャプチャを取得する
}

#LifeGameの処理を実装
#誕生：死んでいるセルに隣接する生きたセルがちょうど3つあれば、次の世代が誕生する。
#生存:生きているセルに隣接する生きたセsルが2つか3つならば、次の世代でも生存する。
#過疎:生きているセルに隣接する生きたセルが1つ以下ならば、過疎により死滅する。
#過密:生きているセルに隣接する生きたセルが4つ以上ならば、過密により死滅する。
#枠外のセルは、死んでいるセルとみなす
function Update-NextGeneration()
{
    $BASE = $script:CURRENT
    $NEXT =@()
    $i = 0
    $ife = 0
    while($i -lt $height){
        $j = 0
        $line = ""
        while($j -lt $width){
           $cell = $BASE[$i][$j]
           $score = Evaluate-Cell $i $j
           $result = $cell
           #$log = "x:"+$j+" y:"+$i+" Score:"+$score+" -"
           #$log >> re.txt
           if($cell -match $script:Live){
           #生きている場合
               #生存
               if(($score -eq 2) -or ($score -eq 3)){
                   $result = $script:Live
               }else{
               #過疎or過密
                $result = $script:Dead
               }
           }
           
           #死んでいる場合
           if($cell -match $script:Dead){
                if($score -eq 3){
                    #誕生
                    $result = $script:Live
                }else{
                    $result =$script:Dead
                }
           }
           if($result -match $script:Live){$life +=1 }
           $line += $result
           $j += 1
        }
        $NEXT += $line
        $i += 1
    }
    $script:GENERATION += 1
    $NEXT += "GENERATION:  $script:GENERATION"
    $script:CURRENT　= $NEXT
}

 function Evaluate-Cell([int]$rNum, [int]$cNum){
    $score = 0
    $iy = -1
    while($iy -le 1){
        $y = $rNum + $iy
        $ix = -1
        while($ix -le 1){
            $x = $cNum + $ix
            $tgr = $script:CURRENT[$y][$x]
            #Write-Host "x:", $x,"y:", $y
            if( ($x -lt 0) -or ($y -lt 0) -or ($x -ge $width) -or ($y -ge $height)){
                #範囲外のため未処理
                $score += 0
            }elseif( ($x -eq $cNum) -and ($y -eq $rNum)){
                #自身のため未処理
                $score += 0
            }else{
                if($tgr -match $script:Live){
                    $score += 1
                }else{
                    $score += 0
                }
            }
            
            $ix += 1          
        }
        $iy += 1
    }
    return $score
}

#画面キャプチャ
function Get-ScreenCapture($name)
{   
    begin {
        Add-Type -AssemblyName System.Drawing, System.Windows.Forms
        $jpegCodec = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | 
            Where-Object { $_.FormatDescription -eq "JPEG" }
    }
    process {
        Start-Sleep -Milliseconds 200

        #Alt+PrintScreenを送信
        [Windows.Forms.Sendkeys]::SendWait("%{PrtSc}")        

        Start-Sleep -Milliseconds 200

        #クリップボードから画像を取得
        $bitmap = [Windows.Forms.Clipboard]::GetImage()    

        #画像保存
        $ep = New-Object Drawing.Imaging.EncoderParameters  
        $ep.Param[0] = New-Object Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality, [long]100)
        $screenCapturePathBase = "${pwd}\${name}"
        $c = 0
        while (Test-Path "${screenCapturePathBase}_${c}.jpg") {
            $c++
        }
        $bitmap.Save("${screenCapturePathBase}_${c}.jpg", $jpegCodec, $ep)
    }
}

# MAIN
$ZERO   = New-Object System.Management.Automation.Host.Coordinates -ArgumentList 0, 0
Clear-Host

# Board Size
$height = 30
$width = $height

$RUI = $host.UI.RawUI
$GENERATION = 0   # 世代

$CURRENT = @()   # 表示する画面文字列
Make-Board         # 初期化
Display-Board
Write-Host " "
Write-Host "Runnning..."
Start-Sleep -millisecond 250 #wait time

while($true){
  Update-NextGeneration
  Start-Sleep -millisecond 250 #wait time
  Display-Board
}