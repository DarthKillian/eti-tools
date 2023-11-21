Add-Type -AssemblyName PresentationFramework

$newIPXamlPath = "$($pwd)\xaml\AddIP.xaml"

if (Test-Path $newIPXamlPath) {
    $loadNewIPXaml = Get-Content $newIPXamlPath -Raw 
}

[xml]$newIPXaml = $loadNewIPXaml
$newIPReader = (New-Object System.Xml.XmlNodeReader $newIPXaml)
$window = [Windows.Markup.XamlReader]::Load($newIPReader)


$saveNewIPBtn = $window.FindName("saveNewIP")
$newIPAddressTxt = $window.findName("newIPAddress")
$newSubnetMaskTxt = $window.FindName("newSubnet_mask")

$newIPAddressTxt.Focus() | Out-Null

# Check if IP is valid
function checkInput {
    Param($interface, $ip, $subnet)
    if ($ip -and $subnet) {
        try {
            [ipaddress] $ip | Out-Null
            [ipaddress] $subnet | Out-Null
        }
        catch {
            $message = "Invalid IP or Subnet Mask"
            [System.Windows.MessageBox]::Show($message, "Warning", $ButtonType)
        }

        # Need to add a proper dedidcated error handle for an IP address already existing... but that adds a bit more complexity.
        # I wrote a generic garbage error collector below that isn't very pretty. Either an IP exists or shits on fire yo
        $newIPCmd = netsh int ipv4 add address "$($interface)" $ip $subnet


    }
    else {
        $message = "IP and Subnet Mask are required"
        [System.Windows.MessageBox]::Show($message, "Warning", $ButtonType)
        $newIPAddressTxt.Focus | Out-Null
    }

    # Set New Static IP
    & cmd.exe /c $newIPCmd
    if ($LASTEXITCODE -ne 0) {
        [System.Windows.MessageBox]::Show("There was an error setting the IP address on the $interface adapter. The IP may already exist. Please check that the IP exists. Otherwise, please report this bug.", "Warning", $ButtonType)
        $newIPAddressTxt.Focus() | Out-Null
    }
}


$saveNewIPBtn.Add_Click({
        checkInput $selectAdapter.SelectedItem $newIPAddressTxt.Text $newSubnetMaskTxt.Text
    })

$window.ShowDialog() | Out-Null