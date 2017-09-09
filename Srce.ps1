##### Snap shot Script #### Managed Disk #####  @debayan Chakraborty @

###Parameter ####
$Vm_name = "Give Name of VM"

$RGname = "Input Name of Source Resource Group"
$destRGname = "Input Name of destination resourceGroup"
$subscription_name = "Give the right sunscription Name"

 Select-AzureRmSubscription -SubscriptionName $subscription_name

    Try {
  $vm = Get-AzureRMVM -ResourceGroupName $RGname -Name $Vm_name -ErrorAction Stop

      }
     Catch {
      Write-Error "VM name & Resourcegroup Name is not matched"

      Break;
     }


     Function DateStamp {

     $date =Get-Date -UFormat "%Y%m%d"
     $date.ToString()
     }

Function  Create_backup_Os_Disk {
         $dt = DateStamp
      $osdisk = $vm.StorageProfile.OsDisk

      $snapshotname= $vm.Name +"_"+$dt  +"os_snapshot"
      Try {
      $diskconfig = Get-AzureRMDisk -ResourceGroupName $RGname -DiskName $osdisk.Name -ErrorAction Stop
       }

       Catch
       {
       Write-Error "Vm and Os disk are not in same resource group. Please contact CloudOps"
       Break
       }
      $snapShotConfig =  New-AzureRmSnapshotConfig -SourceUri $diskconfig.Id -CreateOption Copy -Location $diskconfig.Location -AccountType $diskconfig.AccountType
      Try{
          $snapShot=  New-AzureRmSnapshot -Snapshot $snapShotConfig -SnapshotName  $snapshotname -ResourceGroupName $destRGname -ErrorAction Stop
       
       }
       catch {
       write-Error " Destination Resource group  does not exist"
       Break
       }
 
       $diskname = "backup"+$dt + "_" +$diskconfig.Name
       
    $diskConfigaration = New-AzureRmDiskConfig -AccountType $diskconfig.AccountType -Location $diskconfig.Location -CreateOption copy -SourceResourceId $snapShot.Id
     $osDisk = New-AzureRmDisk -DiskName $diskname -Disk $diskConfigaration -ResourceGroupName $destRGname
  if ( $osDisk.ProvisioningState -eq "Succeeded")
        {
          Write-Output "OsDiskbackup done  new disk name $diskname "
        }
        else{

        Write-Output "Kindly wait" 
    
    }

}


Create_backup_Os_Disk

Function  Create_backup_Data_Disk
{

 $datadisks = $vm.StorageProfile.DataDisks

     if ( $datadisks.Count -ge 1 )
        { 

           foreach ( $data in $datadisks)
            {
               Try 
                  {
                  $sourceDisk = Get-AzureRMDisk -ResourceGroupName $RGname -DiskName $data.Name


                  }
                  Catch {

                    Write-Error "VM Resource Group and Data Drive ( $data.Name) Resource group are not same"
                    Break

                  } $dt = DateStamp

                   $snapname = $data.name + "_"+$dt+"Snapshot"
          $snapshotConfig =  New-AzureRmSnapshotConfig -SourceUri $sourceDisk.Id -CreateOption Copy -Location $sourceDisk.Location -AccountType $sourceDisk.AccountType
      Try{
          $snapShot=  New-AzureRmSnapshot -Snapshot $snapshotConfig -SnapshotName  $snapname  -ResourceGroupName $destRGname -ErrorAction Stop
       
       }
       catch {
       write-Error " Destination Resource group  does not exist"
       Break
       }    
       $diskname = "backup" +$dt+ "_"+$data.Name
       $newdiskConfigaration = New-AzureRmDiskConfig -AccountType $sourceDisk.AccountType -Location $sourceDisk.Location -CreateOption copy -SourceResourceId $snapShot.Id
     $newDisk = New-AzureRmDisk -DiskName $diskname -Disk $newdiskConfigaration -ResourceGroupName $destRGname
        if ( $newDisk.ProvisioningState -eq "Succeeded")
        {
          Write-Output "Diskbackup done  new disk name $diskname "
        }
        else{

        Write-Output "Kindly wait" 
        }
         start-sleep -Seconds 5
            }


       }

    else 
    {
      Write-Output "VM does not have any Data Drive Currently"

    }

}

Create_backup_Data_Disk
