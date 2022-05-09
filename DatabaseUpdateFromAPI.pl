package Device;
use warnings; 
use strict; 
sub new {
      my $class = shift;
      my $self = {
      EntryID                => defined($_[0]) ? $_[0] : '',         #############################################################################             
      Name                   => defined($_[1]) ? $_[1] : '',         # A class created to hold information on devices in ___ and ___________.    # 
      Serial                 => defined($_[2]) ? $_[2] : '',         # The reason for this class is to do data integrity checking and data       #
      Hardware_Address       => defined($_[3]) ? $_[3] : '',         # updating as ___ data is input by people while ___________ has some fields #
      Last_Modified          => defined($_[4]) ? $_[4] : '',         # that are auto populated by devices.                                       #
      Status                 => defined($_[5]) ? $_[5] : '',         #############################################################################
      Location               => defined($_[6]) ? $_[6] : '', 
      Is____________________ => defined($_[7]) ? $_[7] : '', 
      other_serial              => "",
      other_hardware_address    => "",
      other_location_code       => "",
      other_product             => "",
      other_name                => "",
      Lat_Long                  => "",
      other_latlong_string      => "",
      other_latlong             => "",
      update_flag               => 0,
      new_flag                  => 0,
      missing_flag              => 0,
      other_no_location_flag    => 0 

      };
      bless $self, $class;
      return $self;
}

sub get_useful_fields { 
   return [$_[0]->{ EntryID }, $_[0]->{ Name }, $_[0]->{ Serial },                                    ###############################################################
         $_[0]->{ Hardware_Address },$_[0]->{ Status }, $_[0]->{ Location },                          # Function to grab all the fields used in the email generator #
         $_[0]->{ other_serial }, $_[0]->{ other_hardware_address }, $_[0]->{ other_location_code },  ###############################################################
         $_[0]->{ other_product }, $_[0]->{other_name}];
}

sub ____Lat_Long_Check { 
   if (ref($_[0]->{Lat_Long}) eq 'ARRAY'){
      return 1; 
   }
   return 0; 
} 
sub other_latlong_check {
   if (ref($_[0]->{other_latlong}) eq 'ARRAY' ){
      return 1; 
   }
   return 0;
}

sub get_Status {
   return $_[0]->{Status};
}

sub import_other {
   my $self = shift;
   my $array = shift;                                      ######################################################
   my @array = @$array;                                    # Class Method to read in data from ___________ into #
   $self->{other_name}                = lc($array[0]);     # the class object Device for interal usage          #
   $self->{other_serial}              = $array[1];         ######################################################
   $self->{other_hardware_address}    = $array[2];
   $self->{other_location_code}       = $array[3];
   $self->{other_product}             = $array[4];
   $self->{other_latlong_string}      = $array[5];
}

sub compare {
   my $self = shift;
   if ($self->{EntryID} && $self->{EntryID} ne "Not Found" && $self->{other_name}){  ##########################################################################
         $self->{update_flag} = 1;                                                   # Method compare sets a flag for record changes in ____.                 #
   }                                                                                 # If there is Entry ID and has a ___________ name: update the record     #
   elsif ($self->{EntryID} eq "Not Found" && $self->{other_name}){                   # If no Entry ID, but there is an other_name found: Make a new record    #
         $self->{new_flag} = 1;                                                      # If there is Entry ID but no other_name then change ___ status          #
   }                                                                                 ########################################################################## 
   elsif ($self->{EntryID} && !$self->{other_name} && $self->{Is____________________}){
      $self->{missing_flag} = 1; 
   }
}

sub get_____Lat_Long {
   my $self = shift; 
   my $lat_check = shift;                                         #################################################################
   my %lat_check = %{$lat_check};                                 # reads in hash of ___ locations to match up with location_code #
   if(exists($lat_check{$self->{Location}})){                     # in device object. If match is found the Lat Long Coordinates  #
      my $value = $lat_check{$self->{Location}};                  # are added to the Device for geographic distance check later   #
      if(!defined($value)){                                       #################################################################
         $self->{Lat_Long} = "No Data";
      }
      elsif($lat_check{$self->{Location}} =~ /(.*),(.*)/){
         $self->{Lat_Long} =  [$1,$2];
      }
      else{
         $self->{Lat_Long} = "No Data";
      }
   }
}

package ___test;
use JSON;
use Sys::Hostname;            # A class for reading the system server
use Getopt::Std;              # A standard input for parameters
use warnings; 
use strict;

# Method: getData
# Param: N/A
# Return: A hash of the routers that fit the fields we want
sub getData {
   my $routersString = # CALL TO DEVICE DATA ON OTHER WEBSITE
   my $routersHashref = JSON::decode_json($routersString);  # Turn the JSON String into a massive reference hash
   my %routerHash = %$routersHashref;                       # Dereference the outter hash
   my @routers = @{$routerHash{data}};                      # Dereference and get the data array
   # Empty hash to return
   my %return = ();
   # For every item in the router array, dereference it and grab our target fields and add to our return hash
   foreach my $i (@routers){
      my %temp = %$i;
      my $location_code = $temp{description};
      if($temp{name} =~ m/^__.*/){
         my $location = '';
         if($location_code =~ m/\[(.*)\]/){
            $location = $1; 
         }
         $return{lc($temp{name})} = [lc($temp{name}),$temp{serial_number},$temp{mac},$location,$temp{product},$temp{last_known_location}];
      }
   }
   # Return the return hash
   return %return;
}

sub getDataLocations {
   my $routersString = ##### GET DATA FROM DIFFERENT WEB SERVICE
   my $routersHashref = JSON::decode_json($routersString);  # Turn the JSON String into a massive reference hash
   my %routerHash = %$routersHashref;                       # Dereference the outter hash
   my @routers = @{$routerHash{data}};                      # Dereference and get the data array
   # Empty hash to return
   my %return = (); 
   for my $location (@routers){
      my %hash = %{$location};
      $return{$hash{'resource_url'}} = [$hash{'latitude'},$hash{'longitude'}];
   }
   return %return; 
}

sub email_maker { 
   # Read in 5 lists to be turned into HTML tables to be emailed as record changes 
   # These tables are: records that have been updated in ___, records that are added to ____,
   # records with status changes, devices that have different location codes between ___ and _________,
   # and devices that are geographically far apart from each other 

   # Outputs tables in the form of:    
   #
   # "Updated ____ Records of _________ Devices"
   # |Device Name|Old Serial	New Serial|	Old Hardware Address   |	New Hardware Address|                    |  
   # ...
   # "New ___ Records of ___________ Devices"
   # |Device Name      |	Serial        |	Hardware Address |	Location    |
   # ...
   # "Status Changes in ____ after No ___________ Device was Found"
   # |Device Name|	Serial|	Hardware Address|	Location|Old Status|	New Status|	Record Change                            |
   # ...
   # "Mismatching Location Codes so Not Update"
   # |Name	    |____Location|	_______Location|
   # ... 
   # "Devices Further Away than Desired"
   # |Distance|	Name   |	___ Location|	___ Location|		
   # ... 

   # EntryID                    0               ###################################################
   # Name                       1               # Look Up Table for index of useful fields return #
   # Serial                     2               ################################################### 
   # Hardware_Address           3               
   # Status                     4               
   # Location                   5                
   # other_serial               6
   # other_hardware_address     7
   # other_location_code        8
   # other_product              9 
   my @list_of_updated_logs = @{$_[0]}; 
   my @list_of_new_logs = @{$_[1]}; 
   my @list_of_status_changed_logs = @{$_[2]}; 
   my @mismatched_location_codes = @{$_[3]};
   my @devices_with_large_distances = @{$_[4]}; 
   my @location_code_errors = @{$_[5]};
   my $updated_log_table = "<table border=\"1\"><tr><th>Device Name</th><th>Old Serial</th><th>New Serial</th><th>Old Hardware Address</th><th>New Hardware Address</th></tr>";
   for my $log (@list_of_updated_logs){
         my @entry = @{$log};
         if($entry[2] eq $entry[6]){
            $entry[2] = '';
            $entry[6] = '';                     ######################################################## 
         }                                      # blanks out unchanged fields for easier visualization #
         if($entry[3] eq $entry[7]){            # if both are unchanged then no need to add to table   #
            $entry[3] = '';                     ########################################################
            $entry[7] = ''; 
         }
         if($entry[7] || $entry[6]){
            my $body = "<tr><th>".$entry[1]."</th><th>".$entry[2]."</th><th>".$entry[6]."</th><th>".$entry[3]."</th><th>".$entry[7]."</th></tr>";
            $updated_log_table = $updated_log_table.$body;
         }
      }

   $updated_log_table = $updated_log_table."</table>"; 

   my $new_log_table = "<table border=\"1\"><tr><th>Device Name</th><th>Serial</th><th>Hardware Address</th><th>Location</th></tr>";
   for my $log (@list_of_new_logs){
         my @entry = @{$log};
         my $body = "<tr><th>".$entry[10]."</th><th>".$entry[6]."</th><th>".$entry[7]."</th><th>".$entry[8]."</th></tr>";
         $new_log_table = $new_log_table.$body;
   }
   $new_log_table = $new_log_table."</table>";

   my $status_changed_log_table = "<table border=\"1\"><tr><th>Device Name</th><th>Serial</th><th>Hardware Address</th><th>Location</th><th>Old Status</th><th>New Status</th><th>Record Change</th></tr>";
   for my $log (@list_of_status_changed_logs){
         my @entry = @{$log};
         my $status = $entry[4];
         my $change = "no change";                                     #################################################
         if($status == 1){                                             # change status if 1 (active) to 0 (pending) or #  
            $status = 0;                                               # 2 (takeout) to 3 (deleted)                    #
            $change = "Not found in ____________, set to pending";     #################################################
         }
         if($status == 2){
            $status = 3; 
            $change = "Not found in ____________, record was deleted";
         }
         my $body = "<tr><th>".$entry[1]."</th><th>".$entry[2]."</th><th>".$entry[3]."</th><th>".$entry[5]."</th><th>".$entry[4]."</th><th>".$status."</th><th>".$change."</th></tr>";
         $status_changed_log_table = $status_changed_log_table.$body;
   }
   $status_changed_log_table = $status_changed_log_table."</table>";

   my $mismatched_location_codes_table = "<table border=\"1\"><tr><th>Name</th><th>____________</th><th>____________</th></tr>";
   for my $log (@mismatched_location_codes){
      my @list = @{$log};                                                                         
      my $body = "<tr><th>".$list[0]."</th><th>".$list[1]."</th><th>".$list[2]."</th></tr>"; 
      $mismatched_location_codes_table = $mismatched_location_codes_table.$body; 
   }
   $mismatched_location_codes_table = $mismatched_location_codes_table."</table>";

   my $devices_with_large_distances_table = "<table border=\"1\"><tr><th>Distance</th><th>Name</th><th>___ Location</th><th>____________</th><tr>"; 
   for my $list (@devices_with_large_distances){
      my @list = @{$list};
      my $body = "<tr><th>".$list[0]."</th><th>".$list[1]."</th><th>".$list[2]."</th><th>".$list[3]."</th></tr>";
      $devices_with_large_distances_table = $devices_with_large_distances_table.$body; 
   }
   $devices_with_large_distances_table = $devices_with_large_distances_table."</table>";

   my $location_code_input_table = "<table border=\"1\"><tr><th>____________ Device</th><th>Location Code</th><tr>";
   for my $log (@location_code_errors){
         my @entry = @{$log};
         my $body = "<tr><th>".$entry[10]."</th><th>".$entry[8]."</th></tr>";
         $location_code_input_table = $location_code_input_table.$body; 
   }
   my $header1 = "<h3>Updated ___ Records of ____________ Devices</h3>"; 
   my $header2 = "<h3>New ___ Records of ____________ Devices</h3>";                          #############################################
   my $header3 = "<h3>Status Changes in ___ after No ____________ Device was Found</h3>";     # Combine Table headers and body for output #
   my $header4 = "<h3>Mismatching Location Codes so Not Update</h3>";                         # in email                                  #
   my $header5 = "<h3>Devices Further Away than Desired</h3>";                                #############################################
   my $header6 = "<h3>Location Code Input Error</h3>"; 
   my $tables = $header1.$updated_log_table.$header2.$new_log_table.$header3.$status_changed_log_table.$header4.$mismatched_location_codes_table.$header5.$devices_with_large_distances_table.$header6.$location_code_input_table; 
   return $tables; 
}

sub generateEmail {
    ### generates email from interal library ###
}

sub generate_km_difference {
   my @latlongarray1 = @{$_[0]};                                       # Converts latlong coordinates to KM difference
   my @latlongarray2 = @{$_[1]};                                          
   my $value = $IDAS->geoDeltaLatLng(@latlongarray1,@latlongarray2);  
   return $value; 
}
###MAIN BODY OF LOGIC ###

# Purpose of the program: to read in records from ___ and ___________ and update ___ 
# Based on information from ____________. If there is a matching record in ____________ based on the device name
# and it has matching location code, update the record with the serial number and hardware address found in ____________ and 
# add to email under updated records. 
# If there is a match but no location code, add that to the discrepancy email for location mismatch.
# If there is no match for ___ record, change status and add to status changed table.
# If there is no match for ____________ Record, add that device to ___.
# If there is a match and there is lat long information on both ___ and ____________ do calc to find KM distance apart and if 
# greater than 0.5 add to far away distance table. 

my %_______hashes = getData();
my @logs  = ### GET DATA FROM DATABASE; 
my @location_codes = #GET DATA FROM DATABASE; 

my %location_hash;
for my $location (@location_codes){
   $location_hash{$location->[0]} = $location->[1];
}
my %alteredlog;
for my $ORA_LOG (@logs){
   my @log = @{$ORA_LOG};
      if ($log[1] =~ /^mr.{5}\d{3}/i){
         my $location_code = '';
         if(defined($log[6])){
               $location_code = $log[6];                       ########################################################################### 
         }                                                     # Take all logs because updates could potentially happen for              #
         my $comment_contains_key_value = 0;                   # a device not tagged in the comments with ____________.                  # 
         if (defined($log[7])){                                # Without the ____________ tag, the device should not have a              #
            if ($log[7] =~ /(?i)keyvalue|key value/){          # status change as the device probably has nothing to do with ____________#
               $comment_contains_key_value  = 1;               ###########################################################################
            }
         }

         $alteredlog{$log[1]} = Device->new($log[0],$log[1],$log[2],$log[3],$log[4],$log[5],$location_code,$comment_contains_key_value);
         $alteredlog{$log[1]}->get_____Lat_Long(\%location_hash);
      }
}

for my $device (keys %alteredlog){ 
   for my $cdevice (keys %_______hashes){                                 #################################################### 
      if (lc $device eq lc $cdevice){                                     # populate device with other data if matching name #
         $alteredlog{$device}->import_other($_______hashes{$cdevice});    #################################################### 
      }
   }
}


for my $cdevice (keys %_______hashes){                                      ####################################################
   my $exists_in________and____ = 0;                                        # makes new device if not found in ___ but is a    #
   my @_______device = @{$_______hashes{$cdevice}};                         # device pulled from ____________.                 #
   for my $device (keys %alteredlog){                                       ####################################################
      if (lc($alteredlog{$device}->{Name}) eq lc($_______device[0])){       
            $exists_in________and____ = 1; 
      }
   }
   if ($exists_in________and____ == 0){                                                                                    ###################################################
      my $newdevice = Device->new("Not Found","Not Found","Not Found","Not Found","Not Found","Not Found","Not Found");    # Create an empty device to input other data into.#
      $newdevice->import_other($_______hashes{$cdevice});                                                                  ################################################### 
      $alteredlog{$cdevice} = $newdevice;                                                                                  
   }
}

my %other_locations = getDataLocations();                          #################################################
for my $device (keys %alteredlog){                                 # Populate ____________ latlong data into device#
   if (defined($alteredlog{$device}->{other_latlong_string})){     # from hash of data location information        #
      my $value = $alteredlog{$device}->{other_latlong_string};    #################################################
      if(exists($other_locations{$value})){
         $alteredlog{$device}->{other_latlong} = $other_locations{$value};
      }
   }
}

my @devices_with_large_distances;                                                                                        ##################################################################  
for my $device (keys %alteredlog){                                                                                       # Check to see both ___ and other have known location distances  # 
   if ( $alteredlog{$device}->____Lat_Long_Check() && $alteredlog{$device}->other_latlong_check()  ){                    # find out the difference and if > 0.5 report it                 # 
      my $distance = generate_km_difference($alteredlog{$device}->{____Lat_Long},$alteredlog{$device}->{other_latlong}); ################################################################## 
      if ($distance > 0.5){                                                                                             
         push(@devices_with_large_distances,[$distance,$alteredlog{$device}->{Name},$alteredlog{$device}->{Location}, $alteredlog{$device}->{other_location_code}]);
      }
   }
}

my @list_of_updated_logs = ();                 #######################################################################
my @list_of_new_logs = ();                     # List of changes or issues to report to email. The following         #
my @list_of_status_changed_logs = ();          # code uses compare to determine which action should be taken if any. #
my @mismatched_location_codes = ();            # useful_fields are just a list of 11 values from the device of which #
my @location_code_errors = ();                 # some are only used in one email table.                              # 
for my $device (keys %alteredlog){             ####################################################################### 
   $alteredlog{$device}->compare();           
   if($alteredlog{$device}->{update_flag} == 1){
      if($alteredlog{$device}->{other_location_code} ne $alteredlog{$device}->{Location}){
         push(@mismatched_location_codes,[$alteredlog{$device}->{other_name},$alteredlog{$device}->{Location},$alteredlog{$device}->{other_location_code}]);
      }
      if ( ($alteredlog{$device}->{Hardware_Address} eq $alteredlog{$device}->{other_hardware_address}) && ($alteredlog{$device}->{Serial} eq $alteredlog{$device}->{other_serial})){
         next; 
      }
      else{
         push( @list_of_updated_logs,$alteredlog{$device}->get_useful_fields()); 

            #### SET DATA ENTRY ####

      }
   }
   if($alteredlog{$device}->{new_flag} == 1){
      $alteredlog{$device}->{Status} = 1;

      push( @list_of_new_logs,$alteredlog{$device}->get_useful_fields() ); 
      
      if(exists($____location_hash{$alteredlog{$device}->{other_location_code}})){

          ###### DO DATABASE ADD ######

      }
      elsif($alteredlog{$device}->{other_location_code} eq ''){

          ###### DO DATABASE ADD ######


      }
      else{

        ###### DO DATABASE ADD ######
          
        push( @location_code_errors,$alteredlog{$device}->get_useful_fields() ); 

      }
   }
   
   if($alteredlog{$device}->{missing_flag} == 1){
      my $status = $alteredlog{$device}->{Status};
      if($status == 1){
         $status = 0; 
         push( @list_of_status_changed_logs,$alteredlog{$device}->get_useful_fields());
      }
      if($status == 2){
         $status = 3; 
         push( @list_of_status_changed_logs,$alteredlog{$device}->get_useful_fields());
      }

    ##### SET DATABASE ENTRY TO MISSING STATUS #####

   }
}

#Generate the html body for the email with email maker then send it off with generate email. 
my $body = email_maker(\@list_of_updated_logs,\@list_of_new_logs,\@list_of_status_changed_logs,\@mismatched_location_codes,\@devices_with_large_distances,\@location_code_errors);
generateEmail($body);
