Add-Type -AssemblyName PresentationFramework

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

# Get all physiscal adpaters
$adapters = Get-NetAdapter -Physical
$intIndex

# Now iterate through them and only get the adapters that are up then assign them to the adapter select box
foreach ($adapter in $adapters) {
   if ($adapter.status -eq "Up") {
      $adapter | ForEach-Object { $selectAdapter.Items.Add($_.Name) } | Out-Null
   }
}

# Get index of selected interface to be used to query interface settings
function getAdapterIndex ($interface) {
   $intIndex = Get-NetIPConfiguration -InterfaceAlias $interface | Select-Object interfaceindex
   return $intIndex.interfaceindex
}

function getAdapterDetails ($interface) {
   # do the get-wmiobject cool stuff here and return
}

<# function checkMode ($interface) {
   $mode = Get-NetIPConfiguration -InterfaceAlias $interface | Select-Object -ExpandProperty NetIPv4Interface | Select-Object dhcp
   if ($mode.dhcp -eq "Enabled") {
      $dhcpOption.IsChecked = $true
   }
   else {
      $staticOption.IsChecked = $true
   }
} #>

# Select the first adapter in the list and focus it
$selectAdapter.SelectedIndex = 0
$selectAdapter.Focus() | Out-Null
# checkMode $selectAdapter.SelectedItem

$intIndex =  getAdapterIndex $selectAdapter.SelectedItem

$interface = getAdapterDetails $intIndex

$selectAdapter.Add_SelectionChanged({ 
      checkMode $selectAdapter.SelectedItem
   })

$window.ShowDialog() | Out-Null