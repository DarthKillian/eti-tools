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
$reloadBtn = $window.FindName("reload")

# Get all physiscal adpaters
# Now iterate through them and only get the adapters that are up then assign them to the adapter select box
function checkAdapters () {
   # Clear the listbox when the reload button gets clicked and to make sure nothing funky exists before enumerating our items
   $selectAdapter.Items.Clear()
   foreach ($adapter in Get-NetAdapter -Physical) {
      if ($adapter.status -eq "Up") {
         $adapter | ForEach-Object { $selectAdapter.Items.Add($_.Name) } | Out-Null
      }
   }

   # Select the first adapter in the list and focus it
   $selectAdapter.SelectedIndex = 0
   $selectAdapter.Focus() | Out-Null
}

checkAdapters # Run the checkAdapters function

# Get index of selected interface to be used to query interface settings
function getAdapterIndex ($interface) {
   # Write-Host Inside getAdapterIndex
   $intIndex = Get-NetIPConfiguration -InterfaceAlias $interface | Select-Object interfaceindex
   return $intIndex.interfaceindex
}

function getAdapterDetails ($interface) {
   # do the get-wmiobject cool stuff here and return
}

# Check if the adapter mode is dhcp or static
function checkMode ($interface) {
   # Write-Host Inside checkMode
   $mode = Get-NetIPConfiguration -InterfaceAlias $interface | Select-Object -ExpandProperty NetIPv4Interface | Select-Object dhcp
   if ($mode.dhcp -eq "Enabled") {
      $dhcpOption.IsChecked = $true
   }
   else {
      $staticOption.IsChecked = $true
   }
}

$intIndex = getAdapterIndex $selectAdapter.SelectedItem
$interface = getAdapterDetails $intIndex

# Listen for selectAdapter selection change event.
$selectAdapter.Add_SelectionChanged({
      if ($selectAdapter.Items.Count -ne 0) {
         checkMode $selectAdapter.SelectedItem
      }
   })

$reloadBtn.Add_Click({checkAdapters})

$window.ShowDialog() | Out-Null