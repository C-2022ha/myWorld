### Read conf file and retrieve variables
$ScriptPath=$(split-path $PSCommandPath)
$ConfPath="$ScriptPath\script.conf"


Get-Content $ConfPath | Foreach-Object{
	$var = $_.Split('=')
    Set-Variable -Name $var[0] -Value $var[1]
}

Add-Type -AssemblyName System.Web
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

### Parameters to connect to ACTA
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$headers = @{}
$headers.Add("User-Agent","Apache-HttpClient/4.1")

$RetrieveUsers="https://$ACTA_URL/rest/$TENANTID/analytics/Person?filter=((Id+%3E+%271%27)+and+(IsSystemIntegration+!%3D+%27true%27+and+IsSystem+!%3D+%27true%27))&layout=Id,Name,Email,Upn,Perimeter_c,LastAccessTime,EmsCreationTime,IsMaasUser,EmployeeNumber&size=300000&"

#$RetrieveUsers="https://$ACTA_URL/rest/$TENANTID/ems/Person?filter=((Id+%3E+%271%27+and+LastUpdateTime+btw+(1665007200000,1665698399999))+and+(IsSystemIntegration+!%3D+%27true%27+and+IsSystem+!%3D+%27true%27))&layout=Id,Name,Email,Location,OrganizationalGroup,Upn,Perimeter_c,LastAccessTime,EmsCreationTime,IsMaasUser,EmployeeNumber,Company,CostCenter,CodeDEC_c,CodeDR_c,Locale,Avatar,Title,IsVIP,Location.Name,Location.DisplayLabel,Location.DisplayName,Location.FullName,Location.LocationType,Location.IsDeleted,OrganizationalGroup.Name,OrganizationalGroup.IsDeleted,Company.Name,Company.Id,Company.DisplayLabel,Company.CompanyLogo,Company.Tenant,Company.Code,Company.ManagedCustomer,Company.IsDeleted,CostCenter.Id,CostCenter.DisplayLabel,CostCenter.IsDeleted&meta=totalCount&order=EmsCreationTime+desc&size=25000&skip=0"

$RetrieveUserId="https://$ACTA_URL/rest/$TENANTID/ems/Person?filter=((IsSystemIntegration+!%3D+%27true%27+and+IsSystem+!%3D+%27true%27)+and+Upn+%3D+(%27{UPN}%27))&layout=Id,Name,Email,EmployeeNumber,Upn,IsMaasUser"

$RetrieveReqList="https://$ACTA_URL/rest/$TENANTID/ems/Request?filter=(((RequestedForPerson.Id+%3D+%27{id}%27)+or+(RequestedByPerson.Id+%3D+%27{id}%27)+or+(Createur_c.Id+%3D+%27{id}%27)+or+(AssignedToPerson.Id+%3D+%27{id}%27)+or+(ExpertAssignee.Id+%3D+%27{id}%27)+or+(OwnedByPerson.Id+%3D+%27{id}%27)+or+(ClosedByPerson.Id+%3D+%27{id}%27)+or+(ResolvedByPerson.Id+%3D+%27{id}%27)))&layout=Id,ResolvedByPerson.Id,ResolvedByPerson.Name,RequestedForPerson.Id,RequestedForPerson.Name,RequestedByPerson.Id,RequestedByPerson.Name,RecordedByPerson.Id,RecordedByPerson.Name,OwnedByPerson.Id,OwnedByPerson.Name,ExpertAssignee.Id,ExpertAssignee.Name,Createur_c.Id,Createur_c.Name,ClosedByPerson.Id,ClosedByPerson.Name,AssignedToPerson.Id,AssignedToPerson.Name"

$RetrieveIncList="https://$ACTA_URL/rest/$TENANTID//ems/Incident?filter=(Id+%3E+%270%27+and+OwnedByPerson.Id+%3D+(%27{id}%27)+or+RecordedByPerson.Id+%3D+(%27{id}%27)+or+RequestedByPerson.Id+%3D+(%27{id}%27)+or+AssignedPerson.Id+%3D+(%27{id}%27)+or+ClosedByPerson.Id+%3D+(%27{id}%27)+or+ContactPerson.Id+%3D+(%27{id}%27)+or+ExpertAssignee.Id+%3D+(%27{id}%27)+or+LastUpdatedByPerson.Id+%3D+(%27{id}%27))&layout=Id&meta=totalCount&size=250&skip=0"

function get-SSOCookieActa {
    param ( $ACTA_LOGIN, $ACTA_PASSWORD, $ACTA_URL, $TENANTID)

    #$SSO_URL="https://$ACTA_URL/auth/authentication-endpoint/authenticate/token?TENANTID=$ACTA_TENANTID"
    $SSO_URL="https://$ACTA_URL/auth/authentication-endpoint/authenticate/token?TENANTID=$TENANTID"
    
    $Auth="{`"Login`":`"${ACTA_LOGIN}`",`"Password`":`"${ACTA_PASSWORD}`"}"
   
    $SSO_VALUE = Invoke-RestMethod -Uri $SSO_URL -Method POST -Body $Auth -ContentType "application/json"
  
    $cookie = New-Object System.Net.Cookie 
    
    $cookie.Name = "LWSSO_COOKIE_KEY"
    $cookie.Value = "$SSO_VALUE"
    $cookie.Domain = "$ACTA_URL"

    $session.Cookies.Add($cookie);
 
    return $session
   
}

$cookie=get-SSOCookieActa $ACTA_LOGIN $ACTA_PASSWORD $ACTA_URL $TENANTID 

$FINDUSERS_RESULT = Invoke-RestMethod -Uri $RetrieveUsers -WebSession $cookie -Headers $headers

write-output "Upn;email;userid;name" | Out-File "$ScriptPath\extract.csv"

$USERLIST=$FINDUSERS_RESULT.entities

$i=0

#$users=@()
$users=New-object  System.collections.generic.list[System.object]
foreach($user in $USERLIST) {
    #$i
    #$i++
    $Id=$user.properties.Id
    $Upn=$user.properties.Upn
    $Email=$user.properties.Email
    $UserId=$user.properties.EmployeeNumber
    $Name=$user.properties.Name
    $IsMaasUser=$user.properties.IsMaasUser

    if($Upn -like "*@*.*"){

        if($userId){
             $cookie=get-SSOCookieActa $ACTA_LOGIN $ACTA_PASSWORD $ACTA_URL $TENANTID 
             $RetrieveUserId="https://$ACTA_URL/rest/$TENANTID/ems/Person?filter=((IsSystemIntegration+!%3D+%27true%27+and+IsSystem+!%3D+%27true%27)+and+Upn+%3D+(%27$UserId%27))&layout=Id,Name,Email,EmployeeNumber,Upn,IsMaasUser"
             #$RetrieveUserId
             $FINDREQ_RESULT = Invoke-RestMethod -Uri $RetrieveUserId -WebSession $cookie -Headers $headers   
             #$FINDREQ_RESULT     
             $idUser=$FINDREQ_RESULT.entities[0].properties.Id

             if($idUser){

                 $UpnUser=$FINDREQ_RESULT.entities[0].properties.Upn
                 $EmailUser=$FINDREQ_RESULT.entities[0].properties.Email
                 $EmployeeNumberUser=$FINDREQ_RESULT.entities[0].properties.EmployeeNumber
                 $NameUser=$FINDREQ_RESULT.entities[0].properties.Name
                 $IsMaasUserUser=$FINDREQ_RESULT.entities[0].properties.IsMaasUser

                 #$RetrieveReqListURL
                 $RetrieveReqListURL=$RetrieveReqList -replace "{id}",$idUser
                 $FINDREQ_RESULT = Invoke-RestMethod -Uri $RetrieveReqListURL -WebSession $cookie -Headers $headers        
                 $nbReq=$FINDREQ_RESULT.meta.total_count

                 #$RetrieveIncListURL
                 $RetrieveIncListURL=$RetrieveIncList -replace "{id}",$idUser
                 $FINDREQ_RESULT = Invoke-RestMethod -Uri $RetrieveIncListURL -WebSession $cookie -Headers $headers        
                 $nbInc=$FINDREQ_RESULT.meta.total_count

                 write-output "User: $Upn EmployeeId: $UserId nbInc: $nbInc nbReq: $nbReq"


                $myObject = [PSCustomObject]@{  
                     Upn     = $UpnUser
                     Email = $EmailUser
                     UserId = $EmployeeNumberUser
                     Name = $NameUser
                     Id = $idUser
                     IsMaasUser=$NameUser
                     nbInc = $nbInc
                     nbReq = $nbReq
                }


                #$users+=$myObject
                $users.add($myObject)

                if($i%100 -eq 0){
                    $users | ConvertTo-Csv | Out-File "$ScriptPath\extract_users_dupli_$i.csv"
                    $users=New-object  System.collections.generic.list[System.object]
                }

                $i++

            }
        }
     
     }
  
    #write-output "Upn;email;userid;name" | Out-File "$ScriptPath\extract.csv" -Append

}

#$users | ConvertTo-Csv | Out-File "$ScriptPath\extract_users_emails.csv"
