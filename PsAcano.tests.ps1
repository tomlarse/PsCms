$pass = cat .\apiuserpass.txt | ConvertTo-SecureString
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "api", $pass
Describe "New-AcanoSession" {
    Context "Running with params" {
        It "Set the script variables correctly" {
            {New-AcanoSession -Port 445 -APIAddress 10.1.10.100 -Credential $cred -IgnoreSSLTrust} | Should not throw
        }
    }
}

Describe "Get-AcanocoSpaces" {
    Context "List coSpaces" {
        
        It "Returns coSpaces" {
            New-AcanoSession -Port 445 -APIAddress 10.1.10.100 -Credential $cred -IgnoreSSLTrust
            {Get-AcanocoSpaces} | Should Not Throw
        }

        It "Limits correctly" {
            New-AcanoSession -Port 445 -APIAddress 10.1.10.100 -Credential $cred -IgnoreSSLTrust
            $cospaces = Get-AcanocoSpaces -Limit 3
            $cospaces.count | Should be 3
        }

        It "Takes more than one param" {
            New-AcanoSession -Port 445 -APIAddress 10.1.10.100 -Credential $cred -IgnoreSSLTrust
            {Get-AcanocoSpaces -limit 3 -Filter "Test"} | Should not throw
        }

        It "All params work" {
            New-AcanoSession -Port 445 -APIAddress 10.1.10.100 -Credential $cred -IgnoreSSLTrust
            {Get-AcanocoSpaces -limit 3 -Filter "Test" -Offset 1 -TenantFilter asdk -CallLegProfileFilter asdl} | Should not throw        }
    }
}