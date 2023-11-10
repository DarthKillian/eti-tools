Add-Type -AssemblyName PresentationFramework

# Load dependencies
$dependencyPath = "$($pwd)\Dependencies"
Get-ChildItem -Path $dependencyPath -Filter *.ps1 | ForEach-Object {. $_.FullName }


# Set xaml path for window
$xamlPath = "$($pwd)\xaml\MainWindow.xaml"

# Check if xaml exists and read the file
if (Test-Path $xamlPath) {
   $loadXaml = Get-Content $xamlPath -Raw 
}

# Load xaml
[xml]$xaml = $loadXaml
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$selectAdapter = $window.FindName("selectAdapter")
$dhcpOption = $window.FindName("dhcpOption")
$staticOption = $window.FindName("staticOption")
$reloadBtn = $window.FindName("reload")
$staticButtons = $window.FindName("staticButtons")
$adapterOptions = $window.FindName("adapterOptions")
$noAdapters = $window.findName("noAdapters")
$saveStaticBtn = $window.findName("saveStaticBtn")
$addNewIPBtn = $window.FindName("newIPBtn")

# Get text boxes
$ipaddressTxt = $window.FindName("ipaddress")
$subnetMaskTxt = $window.FindName("subnet_mask")
$gatewayTxt = $window.FindName("gateway")
$dnsTxt = $window.FindName("dns")

if ($selectAdapter.Items.Count -ne 0) {
   $noAdapters.Visibility = "Hidden"
   $adapterOptions.Visibility = "Visible"
} else {
   $noAdapters.Visibility = "Visible"
   $adapterOptions.Visibility = "Hidden"
}

# Listen for selectAdapter selection change event.
$selectAdapter.Add_SelectionChanged({
      if ($selectAdapter.Items.Count -ne 0) {
         checkMode $selectAdapter.SelectedItem
         getAdapterDetails $selectAdapter.SelectedItem
         $noAdapters.Visibility = "Hidden"
         $adapterOptions.Visibility = "Visible"
      } else {
         $noAdapters.Visibility = "Visible"
         $adapterOptions.Visibility = "Hidden"
      }
})

$dhcpOption.Add_Click({
   setMode $selectAdapter.SelectedItem "DHCP"
   $staticButtons.Visibility = "Hidden"
})

$staticOption.Add_Click({
   setMode $selectAdapter.SelectedItem "STATIC"
   $staticButtons.Visibility = "Visible"
})

$saveStaticBtn.Add_Click({
   setStaticIP $selectAdapter.SelectedItem $ipaddressTxt.Text $subnetMaskTxt.Text $gatewayTxt.Text $dnsTxt.Text
})

# Reload the adapters after reload button click
$reloadBtn.Add_Click({checkAdapters})
checkAdapters # Run the checkAdapters function

$window.ShowDialog() | Out-Null