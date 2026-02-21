
#-----------------------------
@sorted = sort { $a <=> $b } @unsorted;
#-----------------------------
# @pids is an unsorted array of process IDs
foreach my $pid (sort { $a <=> $b } @pids) {
    print "$pid\n";
}
print "Select a process ID to kill:\n";
chomp ($pid = <>);
die "Exiting ... \n" unless $pid && $pid =~ /^\d+$/;
kill('TERM',$pid);
sleep 2;
kill('KILL',$pid);
#-----------------------------
@descending = sort { $b <=> $a } @unsorted;
#-----------------------------
package Sort_Subs;
sub revnum { $b <=> $a }

package Other_Pack;
@all = sort Sort_Subs::revnum 4, 19, 8, 3;
#-----------------------------
@all = sort { $b <=> $a } 4, 19, 8, 3;
#-----------------------------

