#!/usr/bin/env perl
use strict;
use warnings;
use File::Spec;
use File::Temp qw(tempfile);
use Fcntl qw(:mode);
use POSIX qw(WNOHANG strftime);
use Scalar::Util qw(blessed);
use Time::HiRes qw(time usleep);

# ============================================================
#  slup — a simple scripting language interpreter in Perl
# ============================================================

# --- Variable store ---
my $MAIN_MODULE = 'main';
our $current_module = $MAIN_MODULE;
my %globals;
my %global_arrays;
my %global_dicts;
my %global_decls; # name => { required => 0|1, has_default => 0|1, default_expr => ... }
my $strict_globals_mode = 0;
my %module_vars   = ($MAIN_MODULE => {});
my %module_var_frames = ($MAIN_MODULE => []);
my %module_arrays = ($MAIN_MODULE => {});
my %module_dicts  = ($MAIN_MODULE => {});
my %module_subs   = ($MAIN_MODULE => {}); # name => { params => [...], body => [...] }
my %module_dirs   = ($MAIN_MODULE => '.');
my %loaded_module_paths;
my %module_loading_paths;
my @module_load_stack;
my %module_source_paths;
my $MODULE_NAME_RE = qr/[A-Za-z_][A-Za-z0-9_]*(?:-[A-Za-z0-9_]+)*/;
my $SYMBOL_NAME_RE = qr/[A-Za-z_][A-Za-z0-9_]*(?:(?:->|-|\?)[A-Za-z0-9_]+)*\??/;
my $LIGHT_IDENT_RE = qr/[A-Za-z_][A-Za-z0-9_]*/;
our $call_depth = 0;
our $returning = 0;
our $breaking = 0;
our $continuing = 0;
our $loop_depth = 0;
our $light_fun_block_seq = 0;
our $active_line_no;
our @call_stack;
our %active_calls;
my %sys_capabilities;

sub run_regex_substitute {
    my ($text, $pattern, $replacement, $flags, $name) = @_;
    $text = '' unless defined $text;
    $replacement = '' unless defined $replacement;
    $flags //= '';
    my $re;
    if (ref($pattern) eq 'Regexp') {
        $re = $pattern;
    } else {
        my $pat = defined($pattern) ? "$pattern" : '';
        my $mods = '';
        $mods .= 'i' if $flags =~ /i/;
        $mods .= 'm' if $flags =~ /m/;
        $mods .= 's' if $flags =~ /s/;
        my $qr_pat = $mods ne '' ? "(?$mods:$pat)" : $pat;
        $re = eval { qr/$qr_pat/ };
        die "$name: invalid regex pattern\n" if $@;
    }
    my $out = "$text";
    if ($flags =~ /g/) {
        $out =~ s/$re/$replacement/g;
    } else {
        $out =~ s/$re/$replacement/;
    }
    return $out;
}

# --- Built-in function registry ---
my %builtins = (
    'is-empty' => sub {
        my ($val) = @_;
        return (!defined $val || $val eq '') ? 1 : 0;
    },
    'add' => sub { return ($_[0] // 0) + ($_[1] // 0) },
    'sub' => sub { return ($_[0] // 0) - ($_[1] // 0) },
    'mul' => sub { return ($_[0] // 0) * ($_[1] // 0) },
    'div' => sub { return ($_[0] // 0) / ($_[1] // 1) },
    'mod' => sub { return ($_[0] // 0) % ($_[1] // 1) },
    'concat' => sub { return ($_[0] // '') . ($_[1] // '') },
    'length' => sub { return length($_[0] // '') },
    'upper'  => sub { return uc($_[0] // '') },
    'lower'  => sub { return lc($_[0] // '') },
    'not'    => sub { return $_[0] ? 0 : 1 },
    'eq'     => sub { return ($_[0] // '') eq ($_[1] // '') ? 1 : 0 },
    'neq'    => sub { return ($_[0] // '') ne ($_[1] // '') ? 1 : 0 },
    'gt'     => sub { return ($_[0] // 0) >  ($_[1] // 0) ? 1 : 0 },
    'lt'     => sub { return ($_[0] // 0) <  ($_[1] // 0) ? 1 : 0 },
    'gte'    => sub { return ($_[0] // 0) >= ($_[1] // 0) ? 1 : 0 },
    'lte'    => sub { return ($_[0] // 0) <= ($_[1] // 0) ? 1 : 0 },
    'and'    => sub { return (is_truthy_value($_[0]) && is_truthy_value($_[1])) ? 1 : 0 },
    'or'     => sub { return (is_truthy_value($_[0]) || is_truthy_value($_[1])) ? 1 : 0 },
    'extract' => sub {
        my ($str, $pat) = @_;
        $str //= '';
        die "extract: second argument must be a regex #\"...\"\n" unless defined $pat;
        my @caps = ($str =~ $pat);
        return @caps ? \@caps : [];
    },
    'matchrx' => sub {
        my ($str, $pat) = @_;
        $str //= '';
        die "matchrx: second argument must be a regex #\"...\"\n" unless defined $pat;
        return ($str =~ $pat) ? 1 : 0;
    },
    'rx-sub' => sub {
        my ($text, $pattern, $replacement, $flags) = @_;
        return run_regex_substitute($text, $pattern, $replacement, $flags, 'rx-sub');
    },
    'replace' => sub {
        my ($text, $pattern, $replacement) = @_;
        return run_regex_substitute($text, $pattern, $replacement, '', 'replace');
    },
    'replace-all' => sub {
        my ($text, $pattern, $replacement) = @_;
        return run_regex_substitute($text, $pattern, $replacement, 'g', 'replace-all');
    },
    'array'  => sub { return [@_] },
    'dict'   => sub {
        my %h;
        while (@_) { my $k = shift; $h{$k} = shift }
        return \%h;
    },
    'dict-get'   => sub {
        my ($d, $key) = @_;
        die "dict-get: first argument must be a dict\n" unless ref $d eq 'HASH';
        return $d->{$key};
    },
    'dict-set'   => sub {
        my ($d, $key, $val) = @_;
        die "dict-set: first argument must be a dict\n" unless ref $d eq 'HASH';
        $d->{$key} = $val;
        return $val;
    },
    'dict-keys'  => sub {
        my ($d) = @_;
        die "dict-keys: argument must be a dict\n" unless ref $d eq 'HASH';
        return [keys %$d];
    },
    'dict-has'   => sub {
        my ($d, $key) = @_;
        die "dict-has: first argument must be a dict\n" unless ref $d eq 'HASH';
        return exists $d->{$key} ? 1 : 0;
    },
    'dict-del'   => sub {
        my ($d, $key) = @_;
        die "dict-del: first argument must be a dict\n" unless ref $d eq 'HASH';
        return delete $d->{$key};
    },
    'push'   => sub {
        my $arr = shift;
        die "push: first argument must be an array\n" unless ref $arr eq 'ARRAY';
        push @$arr, @_;
        return $arr;
    },
    'pop'    => sub {
        my ($arr) = @_;
        die "pop: argument must be an array\n" unless ref $arr eq 'ARRAY';
        return pop @$arr;
    },
    'get'    => sub {
        my ($target, $idx) = @_;
        if (ref $target eq 'ARRAY') {
            return $target->[$idx // 0];
        }
        if (ref $target eq 'HASH') {
            return $target->{$idx};
        }
        die "get: first argument must be an array\n";
    },
    'set-index' => sub {
        my ($target, $idx, $val) = @_;
        if (ref $target eq 'ARRAY') {
            $target->[$idx // 0] = $val;
            return $val;
        }
        if (ref $target eq 'HASH') {
            $target->{$idx} = $val;
            return $val;
        }
        die "set-index: first argument must be an array or dict\n";
    },
    'make-fun-ref' => sub {
        my ($name) = @_;
        die "make-fun-ref: missing function name\n" unless defined $name && $name ne '';
        my $subs = module_subs_ref($current_module);
        die "make-fun-ref: unknown function '$name'\n" unless exists $subs->{$name};
        return {
            __slup_lambda => 1,
            module => $current_module,
            subref => $name,
        };
    },
    'len'    => sub {
        my ($arr) = @_;
        die "len: argument must be an array\n" unless ref $arr eq 'ARRAY';
        return scalar @$arr;
    },
    'map'    => sub {
        my ($arr, $fn) = @_;
        die "map: first argument must be an array\n" unless ref $arr eq 'ARRAY';
        die "map: second argument must be fun(...)\n" unless is_slup_lambda($fn);
        my @out;
        for my $v (@$arr) {
            push @out, invoke_lambda($fn, $v);
        }
        return \@out;
    },
    'filter' => sub {
        my ($arr, $fn) = @_;
        die "filter: first argument must be an array\n" unless ref $arr eq 'ARRAY';
        die "filter: second argument must be fun(...)\n" unless is_slup_lambda($fn);
        my @out;
        for my $v (@$arr) {
            push @out, $v if is_truthy_value(invoke_lambda($fn, $v));
        }
        return \@out;
    },
    'save'   => sub {
        my ($path, $content) = @_;
        die "save: missing filename\n" unless defined $path && $path ne '';
        open my $fh, '>', $path or die "save: cannot open '$path': $!\n";
        print $fh ($content // '');
        close $fh;
        return $path;
    },
    'mkdir' => sub {
        my ($dir) = @_;
        die "mkdir: missing directory\n" unless defined $dir && $dir ne '';
        require File::Path;
        File::Path::make_path($dir);
        return $dir;
    },
    'dir-exists' => sub {
        my ($dir) = @_;
        return (defined $dir && -d $dir) ? 1 : 0;
    },
    'file-exists' => sub {
        my ($file) = @_;
        return (defined $file && -f $file) ? 1 : 0;
    },
    'join' => sub {
        my ($delim, $arr) = @_;
        die "join: second argument must be an array\n" unless ref $arr eq 'ARRAY';
        return join(($delim // ''), @$arr);
    },
    'split' => sub {
        my ($delim, $str) = @_;
        return [split quotemeta($delim // ''), ($str // '')];
    },
    'read-file' => sub {
        my ($file) = @_;
        die "read-file: missing filename\n" unless defined $file && $file ne '';
        open my $fh, '<', $file or die "read-file: cannot open '$file': $!\n";
        local $/;
        my $content = <$fh>;
        close $fh;
        return $content;
    },
    'append-file' => sub {
        my ($text, $path) = @_;
        die "append-file: missing path\n" unless defined $path && $path ne '';
        open my $fh, '>>', $path or die "append-file: cannot open '$path': $!\n";
        print $fh ($text // '');
        close $fh;
        return $path;
    },
    'write-lines-file' => sub {
        my ($arr, $path) = @_;
        die "write-lines-file: first argument must be an array\n" unless ref $arr eq 'ARRAY';
        die "write-lines-file: missing path\n" unless defined $path && $path ne '';
        open my $fh, '>', $path or die "write-lines-file: cannot open '$path': $!\n";
        print $fh "$_\n" for @$arr;
        close $fh;
        return $path;
    },
    'read-file-lines' => sub {
        my ($file) = @_;
        die "read-file-lines: missing filename\n" unless defined $file && $file ne '';
        open my $fh, '<', $file or die "read-file-lines: cannot open '$file': $!\n";
        chomp(my @lines = <$fh>);
        close $fh;
        return \@lines;
    },
    'read-dir' => sub {
        my ($dir) = @_;
        die "read-dir: missing directory\n" unless defined $dir && $dir ne '';
        opendir my $dh, $dir or die "read-dir: cannot open '$dir': $!\n";
        my @entries = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
        closedir $dh;
        return \@entries;
    },
    'load' => sub {
        my ($file) = @_;
        die "load: missing filename\n" unless defined $file && $file ne '';
        my $path = resolve_load_path($file);
        my $abs_path = canonicalize_path($path);
        if ($module_loading_paths{$abs_path}) {
            die "load: cyclic dependency detected: " . format_load_cycle($abs_path) . "\n";
        }
        return $file if $loaded_module_paths{$abs_path};

        open my $fh, '<', $path or die "load: cannot open '$file': $!\n";
        chomp(my @lines = <$fh>);
        close $fh;

        my $module = module_name_from_file($path);
        if (exists $module_source_paths{$module} && $module_source_paths{$module} ne $abs_path) {
            die "load: module name collision '$module' between '$module_source_paths{$module}' and '$abs_path'\n";
        }

        $module_loading_paths{$abs_path} = 1;
        push @module_load_stack, $abs_path;
        my $ok = eval {
            $module_source_paths{$module} = $abs_path;
            require File::Basename;
            $module_dirs{$module} = File::Basename::dirname($abs_path);
            module_vars_ref($module);
            module_var_frames_ref($module);
            module_arrays_ref($module);
            module_dicts_ref($module);
            module_subs_ref($module);

            my $nodes = compile_program(\@lines);
            local $current_module = $module;
            run_lines($nodes);
            1;
        };
        my $err = $@;
        pop @module_load_stack;
        delete $module_loading_paths{$abs_path};
        die $err unless $ok;
        $loaded_module_paths{$abs_path} = 1;
        return $file;
    },
    'user-input' => sub {
        my ($prompt) = @_;
        print($prompt // '') if defined $prompt && $prompt ne '';
        my $line = <STDIN>;
        chomp $line if defined $line;
        return $line;
    },
    'die' => sub {
        my ($msg) = @_;
        die(($msg // 'died') . "\n");
    },
    'stderr' => sub {
        my @parts = @_;
        my $out = join('', map { $_ // '' } @parts);
        print STDERR $out, "\n";
        return $out;
    },
    'sh' => sub {
        my ($cmd, $allow_unsafe) = @_;
        die "sh: missing command\n" unless defined $cmd && $cmd ne '';
        if (!$allow_unsafe && $cmd =~ /[|&;<>`\$\\\n]/) {
            die "sh: unsafe shell metacharacters detected; use run()/pipe() or pass 1 as second arg to override\n";
        }
        my $out = `$cmd`;
        die "sh: failed to execute '$cmd': $!\n" if $? == -1;
        if ($? & 127) {
            my $sig = $? & 127;
            die "sh: '$cmd' terminated by signal $sig\n";
        }
        if ($? != 0) {
            my $code = $? >> 8;
            die "sh: '$cmd' exited with status $code\n";
        }
        chomp $out;
        return $out;
    },
    'run' => sub {
        my ($argv, $timeout) = @_;
        die "run: first argument must be an array\n" unless ref($argv) eq 'ARRAY';
        my $timeout_s = parse_timeout_seconds($timeout, 'run');
        return run_command_capture($argv, $timeout_s);
    },
    'pipe' => sub {
        my ($commands, $timeout) = @_;
        die "pipe: first argument must be an array of command arrays\n" unless ref($commands) eq 'ARRAY';
        my $timeout_s = parse_timeout_seconds($timeout, 'pipe');
        return run_pipeline_capture($commands, $timeout_s);
    },
    'mv' => sub {
        my ($old, $new) = @_;
        die "mv: missing arguments\n" unless defined $old && defined $new;
        rename $old, $new or die "mv: cannot rename '$old' to '$new': $!\n";
        return $new;
    },
    'cp' => sub {
        my ($old, $new) = @_;
        die "cp: missing arguments\n" unless defined $old && defined $new;
        require File::Copy;
        File::Copy::copy($old, $new) or die "cp: cannot copy '$old' to '$new': $!\n";
        my @src = stat($old);
        if (@src) {
            chmod($src[2] & 07777, $new) or die "cp: cannot set mode on '$new': $!\n";
            utime($src[8], $src[9], $new) or die "cp: cannot preserve timestamps on '$new': $!\n";
        }
        return $new;
    },
    'sys' => sub {
        my ($capability, @args) = @_;
        die "sys: missing capability\n" unless defined $capability && $capability ne '';
        die "sys: capability must be a string\n" if ref($capability);
        my $handler = $sys_capabilities{$capability};
        return sys_err(38, "sys: unknown capability '$capability'")
            unless defined $handler;
        my $result = eval { $handler->(@args) };
        return $result unless $@;
        my $err = $@;
        $err =~ s/\s+\z//;
        return sys_err(255, "sys/$capability: $err");
    },
    'write-file' => sub {
        my ($text, $path) = @_;
        die "write-file: missing path\n" unless defined $path && $path ne '';
        open my $fh, '>', $path or die "write-file: cannot open '$path': $!\n";
        print $fh ($text // '');
        close $fh;
        return $path;
    },
    'rm' => sub {
        my ($path) = @_;
        die "rm: missing path\n" unless defined $path && $path ne '';
        unlink $path or die "rm: cannot remove '$path': $!\n";
        return $path;
    },
    'cwd' => sub {
        require Cwd;
        return Cwd::getcwd();
    },
    'chdir' => sub {
        my ($dir) = @_;
        die "chdir: missing directory\n" unless defined $dir && $dir ne '';
        CORE::chdir($dir) or die "chdir: cannot change directory to '$dir': $!\n";
        return $dir;
    },
    'true' => sub {
        return 1;
    },
    'false' => sub {
        return 0;
    },
    'sleep' => sub {
        my ($seconds) = @_;
        $seconds = 1 unless defined $seconds;
        die "sleep: seconds must be numeric\n" unless !ref($seconds) && $seconds =~ /^-?\d+(?:\.\d+)?$/;
        my $s = 0 + $seconds;
        $s = 0 if $s < 0;
        if (int($s) == $s) {
            return CORE::sleep(int($s));
        }
        my $start = time();
        while (time() - $start < $s) {
            my $remaining = $s - (time() - $start);
            last if $remaining <= 0;
            usleep(int(($remaining < 0.05 ? $remaining : 0.05) * 1_000_000));
        }
        return 0;
    },
    'umask' => sub {
        my ($mode_raw) = @_;
        if (!defined $mode_raw || $mode_raw eq '') {
            my $prev = CORE::umask();
            CORE::umask($prev);
            return $prev;
        }
        my $mode = parse_mode_value($mode_raw);
        die "umask: mode must be numeric or octal string\n" unless defined $mode;
        return CORE::umask($mode);
    },
    'times' => sub {
        my @t = CORE::times();
        return \@t;
    },
    'kill' => sub {
        my ($signal, @pids) = @_;
        $signal = 'TERM' unless defined $signal && $signal ne '';
        die "kill: expected at least one pid\n" unless @pids;
        return CORE::kill($signal, @pids);
    },
    'wait' => sub {
        my ($pid) = @_;
        $pid = -1 unless defined $pid;
        die "wait: pid must be numeric\n" unless !ref($pid) && $pid =~ /^-?\d+$/;
        my $res = waitpid(int($pid), 0);
        my $status = $?;
        return {
            pid => $res,
            status => $status,
            code => status_to_code($status),
            signal => ($status & 127),
        };
    },
    'basename' => sub {
        my ($path) = @_;
        die "basename: missing path\n" unless defined $path && $path ne '';
        require File::Basename;
        return File::Basename::basename("$path");
    },
    'dirname' => sub {
        my ($path) = @_;
        die "dirname: missing path\n" unless defined $path && $path ne '';
        require File::Basename;
        return File::Basename::dirname("$path");
    },
    'path-type' => sub {
        my ($path) = @_;
        die "path-type: missing path\n" unless defined $path && $path ne '';
        return path_type("$path");
    },
    'path-is-file' => sub {
        my ($path) = @_;
        die "path-is-file: missing path\n" unless defined $path && $path ne '';
        return path_type("$path") eq 'file' ? 1 : 0;
    },
    'path-is-dir' => sub {
        my ($path) = @_;
        die "path-is-dir: missing path\n" unless defined $path && $path ne '';
        return path_type("$path") eq 'dir' ? 1 : 0;
    },
    'path-is-socket' => sub {
        my ($path) = @_;
        die "path-is-socket: missing path\n" unless defined $path && $path ne '';
        return path_type("$path") eq 'socket' ? 1 : 0;
    },
    'path-is-link' => sub {
        my ($path) = @_;
        die "path-is-link: missing path\n" unless defined $path && $path ne '';
        return path_type("$path") eq 'link' ? 1 : 0;
    },
    'path-join' => sub {
        die "path-join: expected at least one segment\n" unless @_;
        return File::Spec->catfile(map { defined $_ ? "$_" : '' } @_);
    },
    'date' => sub {
        return strftime('%Y-%m-%d', localtime(CORE::time()));
    },
    'time' => sub {
        return int(CORE::time());
    },
    'time-iso' => sub {
        return strftime('%Y-%m-%dT%H:%M:%SZ', gmtime(CORE::time()));
    },
);

# Directional and namespaced aliases (keep old names for compatibility)
$builtins{'text->len'}   = $builtins{'length'};
$builtins{'text->upper'} = $builtins{'upper'};
$builtins{'text->lower'} = $builtins{'lower'};
$builtins{'text->replace'} = $builtins{'replace'};
$builtins{'text->replace-all'} = $builtins{'replace-all'};

$builtins{'array->len'}  = $builtins{'len'};
$builtins{'array->get'}  = $builtins{'get'};
$builtins{'array->push'} = $builtins{'push'};
$builtins{'array->pop'}  = $builtins{'pop'};
$builtins{'grep'}        = $builtins{'filter'};

$builtins{'dict->get'}   = $builtins{'dict-get'};
$builtins{'dict->set'}   = $builtins{'dict-set'};
$builtins{'dict->keys'}  = $builtins{'dict-keys'};
$builtins{'dict->has'}   = $builtins{'dict-has'};
$builtins{'dict->del'}   = $builtins{'dict-del'};

$builtins{'dir->exists'} = $builtins{'dir-exists'};
$builtins{'dir->entries'} = $builtins{'read-dir'};
$builtins{'dir->list'} = $builtins{'read-dir'};
$builtins{'file->exists'} = $builtins{'file-exists'};
$builtins{'dir->cwd'} = $builtins{'cwd'};
$builtins{'dir->chdir'} = $builtins{'chdir'};
$builtins{'pwd'} = $builtins{'cwd'};
$builtins{'cd'} = $builtins{'chdir'};
$builtins{'read'} = $builtins{'user-input'};
$builtins{'path->join'} = $builtins{'path-join'};
$builtins{'path->basename'} = $builtins{'basename'};
$builtins{'path->dirname'} = $builtins{'dirname'};
$builtins{'path->type'} = $builtins{'path-type'};
$builtins{'path->is-file'} = $builtins{'path-is-file'};
$builtins{'path->is-dir'} = $builtins{'path-is-dir'};
$builtins{'path->is-socket'} = $builtins{'path-is-socket'};
$builtins{'path->is-link'} = $builtins{'path-is-link'};

$builtins{'file->text'}  = $builtins{'read-file'};
$builtins{'text->file'}  = $builtins{'write-file'};
$builtins{'file->append'} = $builtins{'append-file'};
$builtins{'file->lines'} = $builtins{'read-file-lines'};
$builtins{'lines->file'} = $builtins{'write-lines-file'};
$builtins{'file->remove'} = $builtins{'rm'};
$builtins{'sys->call'} = $builtins{'sys'};
$builtins{'date->today'} = $builtins{'date'};
$builtins{'time->now'} = $builtins{'time'};
$builtins{'time->iso-utc'} = $builtins{'time-iso'};

# ============================================================
#  Module helpers
# ============================================================

sub module_vars_ref {
    my ($module) = @_;
    $module //= $current_module;
    $module_vars{$module} //= {};
    return $module_vars{$module};
}

sub module_arrays_ref {
    my ($module) = @_;
    $module //= $current_module;
    $module_arrays{$module} //= {};
    return $module_arrays{$module};
}

sub module_var_frames_ref {
    my ($module) = @_;
    $module //= $current_module;
    $module_var_frames{$module} //= [];
    return $module_var_frames{$module};
}

sub local_var_lookup {
    my ($module, $name) = @_;
    my $frames = module_var_frames_ref($module);
    for (my $i = $#$frames; $i >= 0; $i--) {
        my $frame = $frames->[$i];
        if (exists $frame->{$name}) {
            return (1, $frame->{$name});
        }
    }
    my $base = module_vars_ref($module);
    if (exists $base->{$name}) {
        return (1, $base->{$name});
    }
    return (0, undef);
}

sub local_var_set {
    my ($module, $name, $value) = @_;
    my $frames = module_var_frames_ref($module);
    if (@$frames) {
        $frames->[-1]{$name} = $value;
    } else {
        module_vars_ref($module)->{$name} = $value;
    }
    return $value;
}

sub module_dicts_ref {
    my ($module) = @_;
    $module //= $current_module;
    $module_dicts{$module} //= {};
    return $module_dicts{$module};
}

sub module_subs_ref {
    my ($module) = @_;
    $module //= $current_module;
    $module_subs{$module} //= {};
    return $module_subs{$module};
}

sub module_name_from_file {
    my ($file) = @_;
    require File::Basename;
    my $name = File::Basename::basename($file);
    $name =~ s/\.[^.]+$//;
    die "load: invalid module name '$name'\n" unless $name =~ /^$MODULE_NAME_RE$/;
    return $name;
}

sub resolve_load_path {
    my ($file) = @_;
    require File::Spec;
    my @candidates;
    push @candidates, $file;
    push @candidates, "$file.slup" if $file !~ /\.[^\/\\]+$/;

    my $base_dir = $module_dirs{$current_module} // '.';
    if (!File::Spec->file_name_is_absolute($file)) {
        push @candidates, File::Spec->catfile($base_dir, $file);
        push @candidates, File::Spec->catfile($base_dir, "$file.slup")
            if $file !~ /\.[^\/\\]+$/;
    }

    for my $candidate (@candidates) {
        return $candidate if -f $candidate;
    }
    return $file;
}

sub canonicalize_path {
    my ($path) = @_;
    my $abs = File::Spec->rel2abs($path);
    eval {
        require Cwd;
        my $real = Cwd::abs_path($abs);
        $abs = $real if defined $real;
        1;
    };
    return $abs;
}

sub format_load_cycle {
    my ($next_abs_path) = @_;
    return join(' -> ', @module_load_stack, $next_abs_path);
}

sub with_line_context {
    my ($msg) = @_;
    chomp $msg;
    return defined $active_line_no ? "line $active_line_no: $msg\n" : "$msg\n";
}

sub resolve_sub_target {
    my ($fname) = @_;
    if ($fname =~ /^($MODULE_NAME_RE)\/($SYMBOL_NAME_RE)$/) {
        my ($module, $sub_name) = ($1, $2);
        my $subs = module_subs_ref($module);
        return ($module, $sub_name) if exists $subs->{$sub_name};
        return;
    }

    my $curr_subs = module_subs_ref($current_module);
    return ($current_module, $fname) if exists $curr_subs->{$fname};

    my $main_subs = module_subs_ref($MAIN_MODULE);
    return ($MAIN_MODULE, $fname) if exists $main_subs->{$fname};

    return;
}

sub is_global_name {
    my ($name) = @_;
    return 0 unless defined $name && is_symbol_name($name);
    return $name =~ /[A-Z]/ && $name !~ /[a-z]/;
}

sub is_local_name {
    my ($name) = @_;
    return 0 unless defined $name && is_symbol_name($name);
    return $name !~ /[A-Z]/;
}

sub is_symbol_name {
    my ($name) = @_;
    return defined $name && $name =~ /^$SYMBOL_NAME_RE$/;
}

sub require_declared_global {
    my ($name, $where, $verb) = @_;
    return unless $strict_globals_mode;
    return if exists $global_decls{$name};
    $verb //= 'use';
    die "$where: undeclared global $verb: '\$$name'\n";
}

sub predeclare_global_if_missing {
    my ($name) = @_;
    $global_decls{$name} //= {
        required => 0,
        has_default => 0,
        default_expr => undef,
    };
}

sub validate_required_globals_runtime {
    for my $name (sort keys %global_decls) {
        my $d = $global_decls{$name};
        next unless $d->{required};
        next if $d->{has_default};
        next if exists $globals{$name};
        die "required global is not assigned at runtime: '\$$name'\n";
    }
}

sub parse_plain_string_literal {
    my ($raw) = @_;
    my $out = '';
    my $i = 0;
    while ($i < length $raw) {
        my $ch = substr($raw, $i, 1);
        if ($ch eq '\\') {
            $i++;
            if ($i >= length $raw) {
                $out .= '\\';
                last;
            }
            my $esc = substr($raw, $i, 1);
            if ($esc eq 'n') {
                $out .= "\n";
            } elsif ($esc eq 't') {
                $out .= "\t";
            } elsif ($esc eq 'r') {
                $out .= "\r";
            } elsif ($esc eq '"' || $esc eq '\\' || $esc eq '$') {
                $out .= $esc;
            } else {
                $out .= '\\' . $esc;
            }
        } else {
            $out .= $ch;
        }
        $i++;
    }
    return $out;
}

sub parse_global_decl_modifier {
    my ($raw) = @_;
    my %spec = (required => 0, has_default => 0, default_expr => undef);
    return \%spec unless defined $raw && $raw =~ /\S/;
    $raw =~ s/^\s+//;
    $raw =~ s/\s+$//;
    if ($raw eq 'required') {
        $spec{required} = 1;
        return \%spec;
    }
    if ($raw =~ /^default\s*\((.*)\)$/) {
        $spec{has_default} = 1;
        $spec{default_expr} = $1;
        return \%spec;
    }
    die "global: expected 'required' or 'default(<expr>)'\n";
}

sub declare_global_spec {
    my ($name, $spec, $where) = @_;
    die "$where: global name must be uppercase: '\$$name'\n" unless is_global_name($name);
    my $existing = $global_decls{$name};
    if ($existing) {
        if ($existing->{required} != $spec->{required}
            || $existing->{has_default} != $spec->{has_default}
            || (($existing->{default_expr} // '') ne ($spec->{default_expr} // ''))) {
            die "$where: conflicting declaration for '\$$name'\n";
        }
        return;
    }
    $global_decls{$name} = {
        required => $spec->{required},
        has_default => $spec->{has_default},
        default_expr => $spec->{default_expr},
    };
}

sub resolve_load_path_from_file {
    my ($from_file, $target) = @_;
    require File::Spec;
    require File::Basename;
    my @candidates;
    push @candidates, $target;
    push @candidates, "$target.slup" if $target !~ /\.[^\/\\]+$/;

    if (!File::Spec->file_name_is_absolute($target)) {
        my $base_dir = File::Basename::dirname($from_file);
        push @candidates, File::Spec->catfile($base_dir, $target);
        push @candidates, File::Spec->catfile($base_dir, "$target.slup")
            if $target !~ /\.[^\/\\]+$/;
    }

    for my $candidate (@candidates) {
        return $candidate if -f $candidate;
    }
    return;
}

sub parse_load_literal_target {
    my ($line) = @_;
    return unless $line =~ /^load\s*\((.*)\)\s*$/;
    my @args = parse_arglist($1);
    return '__DYNAMIC__' unless @args == 1;
    my $arg = $args[0];
    $arg =~ s/^\s+//;
    $arg =~ s/\s+$//;
    return '__DYNAMIC__' unless $arg =~ /^"((?:\\.|[^"\\])*)"$/;
    return parse_plain_string_literal($1);
}

sub static_scan_file {
    my ($path, $state) = @_;
    return if $state->{seen}{$path}++;

    open my $fh, '<', $path or do {
        push @{$state->{errors}}, "$path: cannot open: $!";
        return;
    };
    my @lines = <$fh>;
    close $fh;
    chomp @lines;

    for my $i (0 .. $#lines) {
        my $line = $lines[$i];
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        next if $line eq '' || $line =~ /^#/;

        if ($line =~ /^global\s+\$($SYMBOL_NAME_RE)(?:\s+(.+))?$/) {
            my ($name, $raw_mod) = ($1, $2);
            my $where = "$path:" . ($i + 1);
            my $spec;
            eval { $spec = parse_global_decl_modifier($raw_mod); 1 } or do {
                my $err = $@ || 'global declaration parse error';
                chomp $err;
                push @{$state->{errors}}, "$where: $err";
                next;
            };
            if (!is_global_name($name)) {
                push @{$state->{errors}}, "$where: global name must be uppercase: '\$$name'";
                next;
            }
            my $existing = $state->{decls}{$name};
            if ($existing) {
                if ($existing->{required} != $spec->{required}
                    || $existing->{has_default} != $spec->{has_default}
                    || (($existing->{default_expr} // '') ne ($spec->{default_expr} // ''))) {
                    push @{$state->{errors}}, "$where: conflicting declaration for '\$$name'";
                }
            } else {
                $state->{decls}{$name} = $spec;
            }
            next;
        }

        if ($line =~ /^\$($SYMBOL_NAME_RE)\s*=\s*(.+)$/) {
            my $name = $1;
            my $where = "$path:" . ($i + 1);
            if (!is_global_name($name)) {
                push @{$state->{errors}}, "$where: global names must be uppercase: '\$$name'";
            } else {
                $state->{assigned}{$name} = 1;
            }
            next;
        }

        if ($line =~ /^(?:set|def|let)\s+\$($SYMBOL_NAME_RE)\s*=\s*(.+)$/) {
            my $name = $1;
            my $where = "$path:" . ($i + 1);
            if (is_global_name($name)) {
                $state->{assigned}{$name} = 1;
            } elsif (!is_local_name($name)) {
                push @{$state->{errors}}, "$where: local variable names must be lowercase: '\$$name'";
            }
            next;
        }

        my $target = parse_load_literal_target($line);
        next unless defined $target;
        my $where = "$path:" . ($i + 1);
        if ($target eq '__DYNAMIC__') {
            push @{$state->{errors}}, "$where: static check requires load(\"literal\")";
            next;
        }
        my $resolved = resolve_load_path_from_file($path, $target);
        if (!defined $resolved) {
            push @{$state->{errors}}, "$where: cannot statically resolve load('$target')";
            next;
        }
        static_scan_file($resolved, $state);
    }
}

sub run_static_check {
    my ($entry) = @_;
    my %state = (
        seen => {},
        decls => {},
        assigned => {},
        errors => [],
    );
    static_scan_file($entry, \%state);

    for my $name (sort keys %{$state{assigned}}) {
        next if exists $state{decls}{$name};
        push @{$state{errors}}, "undeclared global assignment: '\$$name'";
    }

    for my $name (sort keys %{$state{decls}}) {
        my $d = $state{decls}{$name};
        next unless $d->{required};
        next if $d->{has_default};
        next if $state{assigned}{$name};
        push @{$state{errors}}, "required global is never assigned: '\$$name'";
    }

    if (@{$state{errors}}) {
        print STDERR "$_\n" for @{$state{errors}};
        return 0;
    }
    return 1;
}

sub slurp_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot open '$path': $!\n";
    local $/;
    my $content = <$fh>;
    close $fh;
    return $content // '';
}

sub normalize_command_argv {
    my ($argv, $ctx) = @_;
    die "$ctx: command must be an array\n" unless ref($argv) eq 'ARRAY';
    die "$ctx: command array must not be empty\n" unless @$argv;
    return [map { defined $_ ? "$_" : '' } @$argv];
}

sub status_to_code {
    my ($status) = @_;
    return -1 if !defined $status || $status == -1;
    return 128 + ($status & 127) if ($status & 127);
    return $status >> 8;
}

sub parse_timeout_seconds {
    my ($timeout, $ctx) = @_;
    return undef unless defined $timeout;
    die "$ctx: timeout must be a positive number of seconds\n"
        unless $timeout =~ /^-?\d+(?:\.\d+)?$/;
    my $seconds = 0 + $timeout;
    die "$ctx: timeout must be a positive number of seconds\n" unless $seconds > 0;
    return $seconds;
}

sub format_timeout_seconds {
    my ($seconds) = @_;
    return sprintf('%.3f', $seconds) + 0;
}

sub kill_pids_gracefully {
    my ($pids_ref) = @_;
    return unless @$pids_ref;
    kill 'TERM', @$pids_ref;
    my $deadline = time() + 0.2;
    while (time() < $deadline) {
        my @alive = grep { kill 0, $_ } @$pids_ref;
        return unless @alive;
        usleep(10_000);
    }
    my @alive = grep { kill 0, $_ } @$pids_ref;
    kill 'KILL', @alive if @alive;
}

sub wait_for_children {
    my ($pids_ref, $timeout_s) = @_;
    my %statuses;
    if (!defined $timeout_s) {
        for my $pid (@$pids_ref) {
            waitpid($pid, 0);
            $statuses{$pid} = $?;
        }
        return (\%statuses, 0);
    }
    my $deadline = defined $timeout_s ? time() + $timeout_s : undef;

    while (1) {
        my $pending = 0;
        for my $pid (@$pids_ref) {
            next if exists $statuses{$pid};
            my $res = waitpid($pid, WNOHANG);
            if ($res > 0) {
                $statuses{$res} = $?;
                next;
            }
            if ($res == -1) {
                $statuses{$pid} = -1;
                next;
            }
            $pending++;
        }
        return (\%statuses, 0) if $pending == 0;

        if (defined $deadline && time() >= $deadline) {
            my @alive = grep { !exists $statuses{$_} } @$pids_ref;
            kill_pids_gracefully(\@alive) if @alive;
            for my $pid (@alive) {
                waitpid($pid, 0);
                $statuses{$pid} = $?;
            }
            return (\%statuses, 1);
        }
        usleep(10_000);
    }
}

sub run_command_capture {
    my ($argv, $timeout_s) = @_;
    my $cmd = normalize_command_argv($argv, 'run');
    my ($outfh, $outpath) = tempfile();
    my ($errfh, $errpath) = tempfile();

    my $pid = fork();
    die "run: fork failed: $!\n" unless defined $pid;
    if ($pid == 0) {
        open STDIN, '<', File::Spec->devnull() or die "run: cannot open devnull: $!\n";
        open STDOUT, '>', $outpath or die "run: cannot open stdout capture: $!\n";
        open STDERR, '>', $errpath or die "run: cannot open stderr capture: $!\n";
        my $ok = exec { $cmd->[0] } @$cmd;
        print STDERR "run: failed to execute '$cmd->[0]': $!\n";
        exit 127;
    }

    close $outfh;
    close $errfh;
    my ($statuses, $timed_out) = wait_for_children([$pid], $timeout_s);
    my $status = $statuses->{$pid};
    my $code = $timed_out ? 124 : status_to_code($status);
    my $out = slurp_file($outpath);
    my $err = slurp_file($errpath);
    if ($timed_out) {
        my $label = format_timeout_seconds($timeout_s);
        $err .= "run: timed out after ${label}s\n";
    }

    unlink $outpath;
    unlink $errpath;

    return {
        code => $code,
        out  => $out,
        err  => $err,
    };
}

sub run_pipeline_capture {
    my ($commands, $timeout_s) = @_;
    die "pipe: command list must not be empty\n" unless @$commands;
    my @cmds = map {
        normalize_command_argv($_, 'pipe');
    } @$commands;

    my ($outfh, $outpath) = tempfile();
    my ($errfh, $errpath) = tempfile();
    close $outfh;
    close $errfh;

    my @pids;
    my $prev_read;
    for my $i (0 .. $#cmds) {
        my ($read_end, $write_end);
        if ($i < $#cmds) {
            pipe($read_end, $write_end) or die "pipe: failed to create pipe: $!\n";
        }

        my $pid = fork();
        die "pipe: fork failed: $!\n" unless defined $pid;
        if ($pid == 0) {
            if (defined $prev_read) {
                open STDIN, '<&', $prev_read or die "pipe: cannot connect stdin: $!\n";
            } else {
                open STDIN, '<', File::Spec->devnull() or die "pipe: cannot open devnull: $!\n";
            }

            if ($i < $#cmds) {
                open STDOUT, '>&', $write_end or die "pipe: cannot connect stdout: $!\n";
            } else {
                open STDOUT, '>', $outpath or die "pipe: cannot open stdout capture: $!\n";
            }

            open STDERR, '>>', $errpath or die "pipe: cannot open stderr capture: $!\n";

            close $read_end if defined $read_end;
            close $write_end if defined $write_end;
            close $prev_read if defined $prev_read;

            my $cmd = $cmds[$i];
            my $ok = exec { $cmd->[0] } @$cmd;
            print STDERR "pipe: failed to execute '$cmd->[0]': $!\n";
            exit 127;
        }

        push @pids, $pid;
        close $prev_read if defined $prev_read;
        if ($i < $#cmds) {
            close $write_end;
            $prev_read = $read_end;
        } else {
            $prev_read = undef;
        }
    }
    close $prev_read if defined $prev_read;

    my ($statuses_ref, $timed_out) = wait_for_children(\@pids, $timeout_s);

    my $last_status = $statuses_ref->{$pids[-1]};
    my $code = $timed_out ? 124 : status_to_code($last_status);
    my $out = slurp_file($outpath);
    my $err = slurp_file($errpath);
    if ($timed_out) {
        my $label = format_timeout_seconds($timeout_s);
        $err .= "pipe: timed out after ${label}s\n";
    }

    unlink $outpath;
    unlink $errpath;

    return {
        code => $code,
        out  => $out,
        err  => $err,
    };
}

sub path_type {
    my ($path) = @_;
    return 'missing' if !defined $path || $path eq '';
    my @st = lstat($path);
    return 'missing' unless @st;
    return sys_type_from_mode($st[2]);
}

sub sys_ok {
    my (%data) = @_;
    return {
        ok   => 1,
        code => 0,
        err  => '',
        %data,
    };
}

sub sys_err {
    my ($code, $err, %data) = @_;
    my $n = defined $code ? int($code) : 1;
    $n = 1 if $n < 0;
    return {
        ok   => 0,
        code => $n,
        err  => (defined $err ? "$err" : 'error'),
        %data,
    };
}

sub sys_type_from_mode {
    my ($mode) = @_;
    my $kind = $mode & S_IFMT;
    return 'file'   if $kind == S_IFREG;
    return 'dir'    if $kind == S_IFDIR;
    return 'link'   if $kind == S_IFLNK;
    return 'char'   if $kind == S_IFCHR;
    return 'block'  if $kind == S_IFBLK;
    return 'fifo'   if $kind == S_IFIFO;
    return 'socket' if $kind == S_IFSOCK;
    return 'other';
}

sub sys_stat_payload {
    my ($st_ref) = @_;
    my @st = @$st_ref;
    my $mode = $st[2] & 07777;
    return (
        type => sys_type_from_mode($st[2]),
        dev => $st[0],
        ino => $st[1],
        mode => $mode,
        'mode-oct' => sprintf('%04o', $mode),
        nlink => $st[3],
        uid => $st[4],
        gid => $st[5],
        rdev => $st[6],
        size => $st[7],
        atime => $st[8],
        mtime => $st[9],
        ctime => $st[10],
        blksize => $st[11],
        blocks => $st[12],
    );
}

sub sys_path_arg {
    my ($ctx, $path) = @_;
    return undef if !defined $path || ref($path) || $path eq '';
    return "$path";
}

sub parse_mode_value {
    my ($raw) = @_;
    return undef unless defined $raw && !ref($raw);
    return oct($raw) if $raw =~ /^0?[0-7]{3,4}$/;
    return 0 + $raw if $raw =~ /^\d+$/;
    return undef;
}

sub dict_get_bool {
    my ($href, $key) = @_;
    return 0 unless ref($href) eq 'HASH' && exists $href->{$key};
    my $v = $href->{$key};
    return ($v && $v ne '0' && $v ne '') ? 1 : 0;
}

sub has_blessed_ref {
    my ($value) = @_;
    return 0 unless ref($value);
    return 1 if blessed($value);
    if (ref($value) eq 'ARRAY') {
        for my $item (@$value) {
            return 1 if has_blessed_ref($item);
        }
        return 0;
    }
    if (ref($value) eq 'HASH') {
        for my $item (values %$value) {
            return 1 if has_blessed_ref($item);
        }
        return 0;
    }
    return 0;
}

sub is_perl_module_name {
    my ($name) = @_;
    return 0 unless defined $name && !ref($name);
    return $name =~ /\A[A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z_][A-Za-z0-9_]*)*\z/ ? 1 : 0;
}

sub is_perl_callable_name {
    my ($name) = @_;
    return 0 unless defined $name && !ref($name);
    return $name =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/ ? 1 : 0;
}

sub require_perl_module {
    my ($module) = @_;
    return sys_err(22, 'perl.module.require: invalid module name')
        unless is_perl_module_name($module);
    my $ok = eval "require $module; 1;";
    if (!$ok) {
        my $err = $@;
        $err =~ s/\s+\z//;
        return sys_err(2, "perl.module.require: $err", module => $module);
    }
    return sys_ok(module => $module, loaded => 1);
}

sub init_sys_capabilities {
    %sys_capabilities = (
        'sys.capabilities' => sub {
            return sys_ok(items => [sort keys %sys_capabilities]);
        },
        'perl.module.require' => sub {
            my ($module) = @_;
            return require_perl_module($module);
        },
        'perl.module.can' => sub {
            my ($module, $function) = @_;
            return sys_err(22, 'perl.module.can: invalid module name')
                unless is_perl_module_name($module);
            return sys_err(22, 'perl.module.can: invalid function name')
                unless is_perl_callable_name($function);
            my $loaded = require_perl_module($module);
            return $loaded unless dict_get_bool($loaded, 'ok');
            no strict 'refs';
            my $can = $module->can($function) ? 1 : 0;
            return sys_ok(module => $module, function => $function, can => $can);
        },
        'perl.call' => sub {
            my ($module, $function, $args) = @_;
            return sys_err(22, 'perl.call: invalid module name')
                unless is_perl_module_name($module);
            return sys_err(22, 'perl.call: invalid function name')
                unless is_perl_callable_name($function);
            $args = [] unless defined $args;
            return sys_err(22, 'perl.call: args must be an array') unless ref($args) eq 'ARRAY';
            return sys_err(95, 'perl.call: blessed references are not allowed in args')
                if has_blessed_ref($args);
            my $loaded = require_perl_module($module);
            return $loaded unless dict_get_bool($loaded, 'ok');
            no strict 'refs';
            my $code = $module->can($function);
            return sys_err(38, "perl.call: function '$function' not found in module '$module'")
                unless $code;
            my $result = eval { $code->(@$args) };
            if ($@) {
                my $err = $@;
                $err =~ s/\s+\z//;
                return sys_err(255, "perl.call: $err", module => $module, function => $function);
            }
            return sys_err(95, 'perl.call: blessed references are not allowed as results', module => $module, function => $function)
                if has_blessed_ref($result);
            if (ref($result) && ref($result) ne 'HASH' && ref($result) ne 'ARRAY') {
                return sys_err(95, "perl.call: unsupported return type " . ref($result), module => $module, function => $function);
            }
            return sys_ok(module => $module, function => $function, result => $result);
        },
        'posix.getpid' => sub {
            return sys_err(22, 'posix.getpid: expected no arguments') if @_;
            return sys_ok(pid => $$);
        },
        'posix.getppid' => sub {
            return sys_err(22, 'posix.getppid: expected no arguments') if @_;
            return sys_ok(pid => getppid());
        },
        'posix.stat' => sub {
            my ($path) = @_;
            my $p = sys_path_arg('posix.stat', $path);
            return sys_err(22, 'posix.stat: missing path') unless defined $p;
            my @st = stat($p);
            if (!@st) {
                my $errno = 0 + $!;
                my $msg = "$!";
                return sys_err($errno, "posix.stat: $msg", path => $p, exists => 0, type => 'missing');
            }
            return sys_ok(path => $p, exists => 1, sys_stat_payload(\@st));
        },
        'posix.lstat' => sub {
            my ($path) = @_;
            my $p = sys_path_arg('posix.lstat', $path);
            return sys_err(22, 'posix.lstat: missing path') unless defined $p;
            my @st = lstat($p);
            if (!@st) {
                my $errno = 0 + $!;
                my $msg = "$!";
                return sys_err($errno, "posix.lstat: $msg", path => $p, exists => 0, type => 'missing');
            }
            return sys_ok(path => $p, exists => 1, sys_stat_payload(\@st));
        },
        'posix.access' => sub {
            my ($path, $mode) = @_;
            my $p = sys_path_arg('posix.access', $path);
            return sys_err(22, 'posix.access: missing path') unless defined $p;
            $mode = 'e' if !defined $mode || $mode eq '';
            return sys_err(22, 'posix.access: mode must only contain e/r/w/x')
                if ref($mode) || $mode !~ /\A[erwx]+\z/;
            my $allowed = 1;
            for my $flag (split //, $mode) {
                if ($flag eq 'e') {
                    $allowed &&= (-e $p ? 1 : 0);
                } elsif ($flag eq 'r') {
                    $allowed &&= (-r $p ? 1 : 0);
                } elsif ($flag eq 'w') {
                    $allowed &&= (-w $p ? 1 : 0);
                } elsif ($flag eq 'x') {
                    $allowed &&= (-x $p ? 1 : 0);
                }
            }
            return sys_ok(path => $p, mode => "$mode", allowed => ($allowed ? 1 : 0));
        },
        'posix.readlink' => sub {
            my ($path) = @_;
            my $p = sys_path_arg('posix.readlink', $path);
            return sys_err(22, 'posix.readlink: missing path') unless defined $p;
            my $target = readlink($p);
            if (!defined $target) {
                my $errno = 0 + $!;
                my $msg = "$!";
                return sys_err($errno, "posix.readlink: $msg", path => $p);
            }
            return sys_ok(path => $p, target => $target);
        },
        'posix.symlink' => sub {
            my ($target, $path) = @_;
            return sys_err(22, 'posix.symlink: missing target') unless defined $target && !ref($target) && $target ne '';
            my $p = sys_path_arg('posix.symlink', $path);
            return sys_err(22, 'posix.symlink: missing path') unless defined $p;
            if (!symlink($target, $p)) {
                my $errno = 0 + $!;
                my $msg = "$!";
                return sys_err($errno, "posix.symlink: $msg", path => $p);
            }
            return sys_ok(path => $p, target => "$target");
        },
        'posix.unlink' => sub {
            my ($path) = @_;
            my $p = sys_path_arg('posix.unlink', $path);
            return sys_err(22, 'posix.unlink: missing path') unless defined $p;
            if (unlink($p)) {
                return sys_ok(path => $p, removed => 1);
            }
            my $errno = 0 + $!;
            my $msg = "$!";
            return sys_err($errno, "posix.unlink: $msg", path => $p, removed => 0);
        },
        'posix.mkdir' => sub {
            my ($path, $mode_raw) = @_;
            my $p = sys_path_arg('posix.mkdir', $path);
            return sys_err(22, 'posix.mkdir: missing path') unless defined $p;
            my $mode = defined $mode_raw ? parse_mode_value($mode_raw) : 0777;
            return sys_err(22, 'posix.mkdir: mode must be numeric or octal string') unless defined $mode;
            if (mkdir($p, $mode)) {
                return sys_ok(path => $p, mode => $mode, 'mode-oct' => sprintf('%04o', $mode & 07777));
            }
            my $errno = 0 + $!;
            my $msg = "$!";
            return sys_err($errno, "posix.mkdir: $msg", path => $p);
        },
        'posix.rmdir' => sub {
            my ($path) = @_;
            my $p = sys_path_arg('posix.rmdir', $path);
            return sys_err(22, 'posix.rmdir: missing path') unless defined $p;
            if (rmdir($p)) {
                return sys_ok(path => $p, removed => 1);
            }
            my $errno = 0 + $!;
            my $msg = "$!";
            return sys_err($errno, "posix.rmdir: $msg", path => $p, removed => 0);
        },
        'posix.chmod' => sub {
            my ($path, $mode_raw) = @_;
            my $p = sys_path_arg('posix.chmod', $path);
            return sys_err(22, 'posix.chmod: missing path') unless defined $p;
            my $mode = parse_mode_value($mode_raw);
            return sys_err(22, 'posix.chmod: mode must be numeric or octal string') unless defined $mode;
            my $changed = chmod($mode, $p);
            if ($changed == 1) {
                return sys_ok(path => $p, mode => $mode, 'mode-oct' => sprintf('%04o', $mode & 07777));
            }
            my $errno = 0 + $!;
            my $msg = "$!";
            return sys_err($errno, "posix.chmod: $msg", path => $p);
        },
        'posix.utime' => sub {
            my ($path, $atime, $mtime) = @_;
            my $p = sys_path_arg('posix.utime', $path);
            return sys_err(22, 'posix.utime: missing path') unless defined $p;
            return sys_err(22, 'posix.utime: atime must be numeric')
                unless defined $atime && !ref($atime) && $atime =~ /^-?\d+(?:\.\d+)?$/;
            return sys_err(22, 'posix.utime: mtime must be numeric')
                unless defined $mtime && !ref($mtime) && $mtime =~ /^-?\d+(?:\.\d+)?$/;
            if (utime(0 + $atime, 0 + $mtime, $p) == 1) {
                return sys_ok(path => $p, atime => 0 + $atime, mtime => 0 + $mtime);
            }
            my $errno = 0 + $!;
            my $msg = "$!";
            return sys_err($errno, "posix.utime: $msg", path => $p);
        },
        'posix.realpath' => sub {
            my ($path) = @_;
            my $p = sys_path_arg('posix.realpath', $path);
            return sys_err(22, 'posix.realpath: missing path') unless defined $p;
            require Cwd;
            my $resolved = Cwd::realpath($p);
            if (defined $resolved) {
                return sys_ok(path => $p, realpath => $resolved);
            }
            my $errno = 0 + $!;
            my $msg = "$!";
            return sys_err($errno, "posix.realpath: $msg", path => $p);
        },
    );
}

init_sys_capabilities();

# ============================================================
#  Parser helpers
# ============================================================

sub parse_string_literal {
    my ($raw) = @_;
    my $out = '';
    my $i = 0;

    while ($i < length $raw) {
        my $ch = substr($raw, $i, 1);
        if ($ch eq '\\') {
            $i++;
            if ($i >= length $raw) {
                $out .= '\\';
                last;
            }
            my $esc = substr($raw, $i, 1);
            if ($esc eq 'n') {
                $out .= "\n";
            } elsif ($esc eq 't') {
                $out .= "\t";
            } elsif ($esc eq 'r') {
                $out .= "\r";
            } elsif ($esc eq '"' || $esc eq '\\' || $esc eq '$') {
                $out .= $esc;
            } else {
                $out .= '\\' . $esc;
            }
        } elsif ($ch eq '$') {
            my $rest = substr($raw, $i);
            if ($rest =~ /^\$($MODULE_NAME_RE)\/($SYMBOL_NAME_RE)/) {
                my ($module, $name) = ($1, $2);
                if (is_global_name($name)) {
                    require_declared_global($name, "string interpolation", 'read');
                    $out .= ($globals{$name} // '');
                } else {
                    die "Invalid local variable name '\$$name' (locals must be lowercase)\n"
                        unless is_local_name($name);
                    my ($found, $val) = local_var_lookup($module, $name);
                    $out .= ($found ? ($val // '') : '');
                }
                $i += length($module) + 1 + length($name);
            } elsif ($rest =~ /^\$($SYMBOL_NAME_RE)/) {
                my $name = $1;
                if (is_global_name($name)) {
                    require_declared_global($name, "string interpolation", 'read');
                    $out .= ($globals{$name} // '');
                } else {
                    die "Invalid local variable name '\$$name' (locals must be lowercase)\n"
                        unless is_local_name($name);
                    my ($found, $val) = local_var_lookup($current_module, $name);
                    if ($found) {
                        $out .= ($val // '');
                    } else {
                        $out .= ($globals{$name} // '');
                    }
                }
                $i += length($name);
            } else {
                $out .= '$';
            }
        } else {
            $out .= $ch;
        }
        $i++;
    }

    return $out;
}

sub split_dict_pair {
    my ($pair) = @_;
    my $depth = 0;
    my $in_quote = 0;
    my $escaped = 0;

    for my $i (0 .. length($pair) - 1) {
        my $ch = substr($pair, $i, 1);

        if ($in_quote && $escaped) {
            $escaped = 0;
            next;
        }
        if ($in_quote && $ch eq '\\') {
            $escaped = 1;
            next;
        }
        if ($ch eq '"') {
            $in_quote = !$in_quote;
            next;
        }
        next if $in_quote;

        if ($ch eq '(' || $ch eq '[' || $ch eq '{') {
            $depth++;
            next;
        }
        if ($ch eq ')' || $ch eq ']' || $ch eq '}') {
            $depth--;
            next;
        }
        if ($ch eq ':' && $depth == 0) {
            my $left = substr($pair, 0, $i);
            my $right = substr($pair, $i + 1);
            return ($left, $right);
        }
    }

    return;
}

sub is_truthy_value {
    my ($value) = @_;
    return ($value && $value ne '0' && $value ne '') ? 1 : 0;
}

sub find_top_level_arrow {
    my ($raw) = @_;
    my $depth = 0;
    my $in_quote = 0;
    my $escaped = 0;
    my $len = length $raw;

    for (my $i = 0; $i < $len - 1; $i++) {
        my $ch = substr($raw, $i, 1);
        if ($in_quote && $escaped) {
            $escaped = 0;
            next;
        }
        if ($in_quote && $ch eq '\\') {
            $escaped = 1;
            next;
        }
        if ($ch eq '"') {
            $in_quote = !$in_quote;
            next;
        }
        next if $in_quote;

        if ($ch eq '(' || $ch eq '[' || $ch eq '{') {
            $depth++;
            next;
        }
        if ($ch eq ')' || $ch eq ']' || $ch eq '}') {
            $depth--;
            next;
        }
        if ($depth == 0 && $ch eq '-' && substr($raw, $i + 1, 1) eq '>') {
            return $i;
        }
    }
    return;
}

sub parse_lambda_expr {
    my ($raw, $label) = @_;
    $label //= 'fun';
    $raw //= '';
    $raw =~ s/^\s+//;
    $raw =~ s/\s+$//;

    my $arrow = find_top_level_arrow($raw);
    die "$label: missing ->\n" unless defined $arrow;

    my $params_raw = substr($raw, 0, $arrow);
    my $body_raw = substr($raw, $arrow + 2);
    $params_raw =~ s/^\s+//;
    $params_raw =~ s/\s+$//;
    $body_raw =~ s/^\s+//;
    $body_raw =~ s/\s+$//;

    die "$label: expected at least one parameter\n" if $params_raw eq '';
    die "$label: missing body expression\n" if $body_raw eq '';

    my @params;
    for my $part (split /,/, $params_raw) {
        $part =~ s/^\s+//;
        $part =~ s/\s+$//;
        die "$label: bad parameter '$part'\n"
            unless $part =~ /^\$($SYMBOL_NAME_RE)$/;
        my $name = $1;
        die "$label: parameter '\$$name' must be lowercase\n"
            unless is_local_name($name);
        push @params, $name;
    }
    die "$label: expected at least one parameter\n" unless @params;

    return {
        __slup_lambda => 1,
        module => $current_module,
        params => \@params,
        body => $body_raw,
    };
}

sub maybe_parse_lambda_expr {
    my ($raw, $label) = @_;
    my $trimmed = $raw // '';
    $trimmed =~ s/^\s+//;
    $trimmed =~ s/\s+$//;
    return unless $trimmed =~ /^\$/;
    return unless defined find_top_level_arrow($trimmed);
    return parse_lambda_expr($trimmed, $label);
}

sub is_slup_lambda {
    my ($value) = @_;
    return ref($value) eq 'HASH' && $value->{__slup_lambda};
}

sub invoke_lambda {
    my ($fn, @args) = @_;
    die "lambda: expected fun(...)\n" unless is_slup_lambda($fn);

    if (exists $fn->{subref}) {
        my $target_module = $fn->{module} // $current_module;
        my $sub_name = $fn->{subref};
        my $sub = module_subs_ref($target_module)->{$sub_name};
        die "lambda: unknown function '$sub_name'\n" unless $sub;

        my $call_id = "$target_module/$sub_name";
        if ($active_calls{$call_id}) {
            die with_line_context("recursion is not allowed for function '$sub_name'; declare it with rec")
                unless $sub->{recursive};
        }

        my $frames = module_var_frames_ref($target_module);
        push @$frames, {};
        push @call_stack, $call_id;
        $active_calls{$call_id}++;
        my $frame = $frames->[-1];
        my $ret;
        my $ok = eval {
            local $call_depth = $call_depth + 1;
            local $returning = 0;
            local $current_module = $target_module;
            for my $idx (0 .. $#{$sub->{params}}) {
                $frame->{$sub->{params}[$idx]} = $args[$idx];
            }
            delete $frame->{'_return'};
            my $body = $sub->{body_nodes} // $sub->{body} // [];
            run_lines($body);
            $ret = $frame->{'_return'};
            1;
        };
        my $err = $@;
        pop @call_stack;
        $active_calls{$call_id}--;
        delete $active_calls{$call_id} unless $active_calls{$call_id};
        pop @$frames;
        die $err unless $ok;
        return $ret;
    }

    my $target_module = $fn->{module} // $current_module;
    my $frames = module_var_frames_ref($target_module);
    push @$frames, {};
    my $frame = $frames->[-1];

    my $ret;
    my $ok = eval {
        local $current_module = $target_module;
        for my $idx (0 .. $#{$fn->{params}}) {
            $frame->{$fn->{params}[$idx]} = $args[$idx];
        }
        $ret = eval_expr($fn->{body});
        1;
    };
    my $err = $@;
    pop @$frames;
    die $err unless $ok;
    return $ret;
}

sub light_escape_string {
    my ($raw) = @_;
    $raw = '' unless defined $raw;
    $raw =~ s/\\/\\\\/g;
    $raw =~ s/"/\\"/g;
    $raw =~ s/\n/\\n/g;
    $raw =~ s/\r/\\r/g;
    $raw =~ s/\t/\\t/g;
    return "\"$raw\"";
}

sub light_regex_literal_to_slup {
    my ($pat, $flags) = @_;
    $pat //= '';
    $flags //= '';
    my $mods = '';
    $mods .= 'i' if $flags =~ /i/;
    $mods .= 'm' if $flags =~ /m/;
    $mods .= 's' if $flags =~ /s/;
    my $full = $mods ne '' ? "(?$mods:$pat)" : $pat;
    $full =~ s/\\/\\\\/g;
    $full =~ s/"/\\"/g;
    return '#"' . $full . '"';
}

sub light_tokenize_expr {
    my ($expr) = @_;
    my @tokens;
    my $i = 0;
    my $len = length $expr;

    while ($i < $len) {
        if (substr($expr, $i) =~ /\A\s+/) {
            $i += length($&);
            next;
        }

        my $prev = @tokens ? ($tokens[-1]{value} // $tokens[-1]{type}) : '';
        my $rest = substr($expr, $i);

        if ($prev eq '=~' && $rest =~ /\As\/((?:\\.|[^\/])*)\/((?:\\.|[^\/])*)\/([A-Za-z]*)/) {
            my ($pat, $rep, $flags) = ($1, $2, $3);
            push @tokens, { type => 'subst', pat => $pat, rep => $rep, flags => $flags };
            $i += length($&);
            next;
        }

        if (($prev eq '=~' || $prev eq '!~') && $rest =~ /\A\/((?:\\.|[^\/])*)\/([A-Za-z]*)/) {
            my ($pat, $flags) = ($1, $2);
            push @tokens, { type => 'regex', pat => $pat, flags => $flags };
            $i += length($&);
            next;
        }

        if ($rest =~ /\A"((?:\\.|[^"\\])*)"/) {
            push @tokens, { type => 'str', value => $1 };
            $i += length($&);
            next;
        }

        if ($rest =~ /\A(\d+(?:\.\d+)?)/) {
            push @tokens, { type => 'num', value => $1 };
            $i += length($&);
            next;
        }

        if ($rest =~ /\A([A-Za-z_][A-Za-z0-9_]*)/) {
            my $word = $1;
            my $next = substr($expr, $i + length($word), 1);
            if ($next eq ':') {
                push @tokens, { type => 'kwlit', value => $word };
                $i += length($word) + 1;
                next;
            }
            if ($word eq 'and' || $word eq 'or' || $word eq 'not') {
                push @tokens, { type => 'op', value => $word };
            } elsif ($word eq 'true' || $word eq 'false') {
                push @tokens, { type => 'bool', value => $word };
            } elsif ($word eq 'nil') {
                push @tokens, { type => 'nil', value => 'nil' };
            } else {
                push @tokens, { type => 'ident', value => $word };
            }
            $i += length($word);
            next;
        }

        if ($rest =~ /\A(==|!=|<=|>=|=~|!~|\+\+)/) {
            push @tokens, { type => 'op', value => $1 };
            $i += length($1);
            next;
        }

        if ($rest =~ /\A([\+\-\*\/%<>])/) {
            push @tokens, { type => 'op', value => $1 };
            $i += 1;
            next;
        }

        if ($rest =~ /\A([()\[\]{},:])/) {
            push @tokens, { type => 'punct', value => $1 };
            $i += 1;
            next;
        }

        die "Unsupported expression token near: " . substr($rest, 0, 20) . "\n";
    }

    push @tokens, { type => 'eof', value => 'eof' };
    return \@tokens;
}

sub light_peek {
    my ($tokens, $pos_ref) = @_;
    return $tokens->[$$pos_ref];
}

sub light_next {
    my ($tokens, $pos_ref) = @_;
    my $tok = $tokens->[$$pos_ref];
    $$pos_ref++;
    return $tok;
}

sub light_parse_expr;
sub light_parse_or;
sub light_parse_and;
sub light_parse_cmp;
sub light_parse_add;
sub light_parse_mul;
sub light_parse_unary;
sub light_parse_postfix;
sub light_parse_primary;

sub light_parse_expr {
    my ($tokens, $pos_ref) = @_;
    return light_parse_or($tokens, $pos_ref);
}

sub light_parse_or {
    my ($tokens, $pos_ref) = @_;
    my $node = light_parse_and($tokens, $pos_ref);
    while (light_peek($tokens, $pos_ref)->{type} eq 'op'
        && light_peek($tokens, $pos_ref)->{value} eq 'or') {
        light_next($tokens, $pos_ref);
        my $rhs = light_parse_and($tokens, $pos_ref);
        $node = { type => 'bin', op => 'or', left => $node, right => $rhs };
    }
    return $node;
}

sub light_parse_and {
    my ($tokens, $pos_ref) = @_;
    my $node = light_parse_cmp($tokens, $pos_ref);
    while (light_peek($tokens, $pos_ref)->{type} eq 'op'
        && light_peek($tokens, $pos_ref)->{value} eq 'and') {
        light_next($tokens, $pos_ref);
        my $rhs = light_parse_cmp($tokens, $pos_ref);
        $node = { type => 'bin', op => 'and', left => $node, right => $rhs };
    }
    return $node;
}

sub light_parse_cmp {
    my ($tokens, $pos_ref) = @_;
    my $node = light_parse_add($tokens, $pos_ref);
    while (light_peek($tokens, $pos_ref)->{type} eq 'op'
        && light_peek($tokens, $pos_ref)->{value} =~ /^(==|!=|<|>|<=|>=|=~|!~)$/) {
        my $op = light_next($tokens, $pos_ref)->{value};
        my $rhs = light_parse_add($tokens, $pos_ref);
        $node = { type => 'bin', op => $op, left => $node, right => $rhs };
    }
    return $node;
}

sub light_parse_add {
    my ($tokens, $pos_ref) = @_;
    my $node = light_parse_mul($tokens, $pos_ref);
    while (light_peek($tokens, $pos_ref)->{type} eq 'op'
        && light_peek($tokens, $pos_ref)->{value} =~ /^(\+|-|\+\+)$/) {
        my $op = light_next($tokens, $pos_ref)->{value};
        my $rhs = light_parse_mul($tokens, $pos_ref);
        $node = { type => 'bin', op => $op, left => $node, right => $rhs };
    }
    return $node;
}

sub light_parse_mul {
    my ($tokens, $pos_ref) = @_;
    my $node = light_parse_unary($tokens, $pos_ref);
    while (light_peek($tokens, $pos_ref)->{type} eq 'op'
        && light_peek($tokens, $pos_ref)->{value} =~ /^(\*|\/|%)$/) {
        my $op = light_next($tokens, $pos_ref)->{value};
        my $rhs = light_parse_unary($tokens, $pos_ref);
        $node = { type => 'bin', op => $op, left => $node, right => $rhs };
    }
    return $node;
}

sub light_parse_unary {
    my ($tokens, $pos_ref) = @_;
    if (light_peek($tokens, $pos_ref)->{type} eq 'op'
        && light_peek($tokens, $pos_ref)->{value} =~ /^(not|\+|-)$/) {
        my $op = light_next($tokens, $pos_ref)->{value};
        my $rhs = light_parse_unary($tokens, $pos_ref);
        return { type => 'unary', op => $op, expr => $rhs };
    }
    return light_parse_postfix($tokens, $pos_ref);
}

sub light_parse_postfix {
    my ($tokens, $pos_ref) = @_;
    my $node = light_parse_primary($tokens, $pos_ref);

    while (1) {
        my $tok = light_peek($tokens, $pos_ref);
        if ($tok->{type} eq 'punct' && $tok->{value} eq '(') {
            light_next($tokens, $pos_ref);
            my @args;
            unless (light_peek($tokens, $pos_ref)->{type} eq 'punct'
                && light_peek($tokens, $pos_ref)->{value} eq ')') {
                while (1) {
                    push @args, light_parse_expr($tokens, $pos_ref);
                    last unless light_peek($tokens, $pos_ref)->{type} eq 'punct'
                        && light_peek($tokens, $pos_ref)->{value} eq ',';
                    light_next($tokens, $pos_ref);
                }
            }
            my $close = light_next($tokens, $pos_ref);
            die "expected ')' in call\n" unless $close->{type} eq 'punct' && $close->{value} eq ')';
            $node = { type => 'call', callee => $node, args => \@args };
            next;
        }

        if ($tok->{type} eq 'punct' && $tok->{value} eq '[') {
            light_next($tokens, $pos_ref);
            my $idx = light_parse_expr($tokens, $pos_ref);
            my $close = light_next($tokens, $pos_ref);
            die "expected ']' in index expression\n" unless $close->{type} eq 'punct' && $close->{value} eq ']';
            $node = { type => 'index', base => $node, idx => $idx };
            next;
        }

        last;
    }

    return $node;
}

sub light_parse_primary {
    my ($tokens, $pos_ref) = @_;
    my $tok = light_next($tokens, $pos_ref);
    die "unexpected end of expression\n" if $tok->{type} eq 'eof';

    return { type => 'num', value => $tok->{value} } if $tok->{type} eq 'num';
    return { type => 'str', value => $tok->{value} } if $tok->{type} eq 'str';
    return { type => 'bool', value => $tok->{value} } if $tok->{type} eq 'bool';
    return { type => 'nil' } if $tok->{type} eq 'nil';
    return { type => 'regex', pat => $tok->{pat}, flags => $tok->{flags} } if $tok->{type} eq 'regex';
    return { type => 'subst', pat => $tok->{pat}, rep => $tok->{rep}, flags => $tok->{flags} } if $tok->{type} eq 'subst';
    return { type => 'str', value => $tok->{value} } if $tok->{type} eq 'kwlit';
    return { type => 'ident', value => $tok->{value} } if $tok->{type} eq 'ident';

    if ($tok->{type} eq 'punct' && $tok->{value} eq '(') {
        my $node = light_parse_expr($tokens, $pos_ref);
        my $close = light_next($tokens, $pos_ref);
        die "expected ')' in expression\n" unless $close->{type} eq 'punct' && $close->{value} eq ')';
        return $node;
    }

    if ($tok->{type} eq 'punct' && $tok->{value} eq '[') {
        my @items;
        unless (light_peek($tokens, $pos_ref)->{type} eq 'punct'
            && light_peek($tokens, $pos_ref)->{value} eq ']') {
            while (1) {
                push @items, light_parse_expr($tokens, $pos_ref);
                last unless light_peek($tokens, $pos_ref)->{type} eq 'punct'
                    && light_peek($tokens, $pos_ref)->{value} eq ',';
                light_next($tokens, $pos_ref);
            }
        }
        my $close = light_next($tokens, $pos_ref);
        die "expected ']'\n" unless $close->{type} eq 'punct' && $close->{value} eq ']';
        return { type => 'array', items => \@items };
    }

    if ($tok->{type} eq 'punct' && $tok->{value} eq '{') {
        my @pairs;
        unless (light_peek($tokens, $pos_ref)->{type} eq 'punct'
            && light_peek($tokens, $pos_ref)->{value} eq '}') {
            while (1) {
                my $key;
                if (light_peek($tokens, $pos_ref)->{type} eq 'kwlit') {
                    $key = { type => 'str', value => light_next($tokens, $pos_ref)->{value} };
                } else {
                    $key = light_parse_expr($tokens, $pos_ref);
                    my $colon = light_next($tokens, $pos_ref);
                    die "expected ':' in dict literal\n"
                        unless $colon->{type} eq 'punct' && $colon->{value} eq ':';
                }
                my $val = light_parse_expr($tokens, $pos_ref);
                push @pairs, { key => $key, val => $val };
                last unless light_peek($tokens, $pos_ref)->{type} eq 'punct'
                    && light_peek($tokens, $pos_ref)->{value} eq ',';
                light_next($tokens, $pos_ref);
            }
        }
        my $close = light_next($tokens, $pos_ref);
        die "expected '}'\n" unless $close->{type} eq 'punct' && $close->{value} eq '}';
        return { type => 'dict', pairs => \@pairs };
    }

    die "unexpected token '$tok->{value}' in expression\n";
}

sub light_ast_to_slup {
    my ($node, $as_callee) = @_;
    $as_callee //= 0;
    my $type = $node->{type};

    if ($type eq 'num') {
        return $node->{value};
    }
    if ($type eq 'str') {
        return light_escape_string($node->{value});
    }
    if ($type eq 'bool') {
        return $node->{value} eq 'true' ? '1' : '0';
    }
    if ($type eq 'nil') {
        return 'nil';
    }
    if ($type eq 'ident') {
        return $as_callee ? $node->{value} : '$' . $node->{value};
    }
    if ($type eq 'regex') {
        return light_regex_literal_to_slup($node->{pat}, $node->{flags});
    }
    if ($type eq 'subst') {
        die "substitution token can only be used with '=~'";
    }
    if ($type eq 'array') {
        return '[' . join(', ', map { light_ast_to_slup($_, 0) } @{$node->{items}}) . ']';
    }
    if ($type eq 'dict') {
        my @pairs;
        for my $pair (@{$node->{pairs}}) {
            my $k = light_ast_to_slup($pair->{key}, 0);
            my $v = light_ast_to_slup($pair->{val}, 0);
            push @pairs, "$k: $v";
        }
        return '{' . join(', ', @pairs) . '}';
    }
    if ($type eq 'call') {
        my $callee = light_ast_to_slup($node->{callee}, 1);
        die "call target must be an identifier\n" if $callee =~ /^\$/;
        my @args = map { light_ast_to_slup($_, 0) } @{$node->{args}};
        return "$callee(" . join(', ', @args) . ")";
    }
    if ($type eq 'index') {
        return "get(" . light_ast_to_slup($node->{base}, 0) . ", " .
            light_ast_to_slup($node->{idx}, 0) . ")";
    }
    if ($type eq 'unary') {
        my $rhs = light_ast_to_slup($node->{expr}, 0);
        return $rhs if $node->{op} eq '+';
        return "sub(0, $rhs)" if $node->{op} eq '-';
        return "not($rhs)" if $node->{op} eq 'not';
    }
    if ($type eq 'bin') {
        my $lhs = light_ast_to_slup($node->{left}, 0);
        my %map = (
            '+' => 'add',
            '-' => 'sub',
            '*' => 'mul',
            '/' => 'div',
            '%' => 'mod',
            '++' => 'concat',
            '==' => 'eq',
            '!=' => 'neq',
            '<' => 'lt',
            '>' => 'gt',
            '<=' => 'lte',
            '>=' => 'gte',
            'and' => 'and',
            'or' => 'or',
        );
        if ($node->{op} eq '=~') {
            if ($node->{right}{type} eq 'subst') {
                return "rx-sub($lhs, " . light_escape_string($node->{right}{pat}) . ", " .
                    light_escape_string($node->{right}{rep}) . ", " .
                    light_escape_string($node->{right}{flags}) . ")";
            }
            my $rhs = light_ast_to_slup($node->{right}, 0);
            return "matchrx($lhs, $rhs)";
        }
        if ($node->{op} eq '!~') {
            my $rhs = light_ast_to_slup($node->{right}, 0);
            return "not(matchrx($lhs, $rhs))";
        }
        my $rhs = light_ast_to_slup($node->{right}, 0);
        my $fn = $map{$node->{op}} // die "unsupported operator '$node->{op}'\n";
        return "$fn($lhs, $rhs)";
    }

    die "unsupported light AST node '$type'\n";
}

sub maybe_normalize_light_expr {
    my ($expr) = @_;
    my $trim = $expr // '';
    $trim =~ s/^\s+//;
    $trim =~ s/\s+$//;
    return $expr if $trim eq '';
    return $expr if $trim =~ /^[\$\@\%#]/;
    return $expr if $trim =~ /[\$\@\%]/;

    my $tokens = eval { light_tokenize_expr($trim) };
    return $expr if $@;
    my $pos = 0;
    my $ast = eval { light_parse_expr($tokens, \$pos) };
    return $expr if $@;
    return $expr unless light_peek($tokens, \$pos)->{type} eq 'eof';
    my $out = eval { light_ast_to_slup($ast, 0) };
    return $expr if $@;
    return $out;
}

sub parse_light_param_list {
    my ($raw_params, $label) = @_;
    $raw_params //= '';
    $label //= 'light form';
    my @params = grep { $_ ne '' } map {
        my $p = $_;
        $p =~ s/^\s+//;
        $p =~ s/\s+$//;
        $p;
    } split /,/, $raw_params;
    for my $p (@params) {
        die "Invalid parameter name '$p' in $label\n" unless $p =~ /^$LIGHT_IDENT_RE$/;
    }
    return @params;
}

sub collect_light_do_block {
    my ($lines_ref, $start_idx, $label) = @_;
    $label //= 'block';
    my @body;
    my $depth = 1;
    my $i = $start_idx;

    while ($i < scalar @$lines_ref) {
        my $raw = $lines_ref->[$i];
        my $line = $raw;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;

        if ($line eq '' || $line =~ /^#/) {
            push @body, $raw;
            $i++;
            next;
        }

        if ($line eq 'end') {
            $depth--;
            if ($depth == 0) {
                $i++;
                last;
            }
            push @body, $raw;
            $i++;
            next;
        }

        if ($line =~ /^if\b/
            || $line =~ /^when\b/
            || $line =~ /^unless\b/
            || $line =~ /^while\b/
            || $line =~ /^foreach\b/
            || $line =~ /^switch\b/
            || $line =~ /^fori\b/
            || $line =~ /^(?:rec|defun)\b/
            || $line =~ /\bfun\s*\[[^\]]*\]\s+do$/) {
            $depth++;
        }

        push @body, $raw;
        $i++;
    }

    die "$label without matching end\n" if $depth != 0;
    return (\@body, $i);
}

sub normalize_light_program {
    my ($lines_ref) = @_;
    my @out;
    my @stack;
    my $tmp_id = 0;
    my $i = 0;

    while ($i < scalar @$lines_ref) {
        my $raw = $lines_ref->[$i];
        my $line = $raw;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;

        if ($line eq '' || $line =~ /^#/) {
            push @out, $raw;
            $i++;
            next;
        }

        if ($line =~ /^defun\s+($LIGHT_IDENT_RE)(?:\s*\[([^\]]*)\])?\s+do$/) {
            my ($name, $raw_params) = ($1, $2 // '');
            my @params = parse_light_param_list($raw_params, 'defun');
            push @stack, { kind => 'defun' };
            my $plist = join(', ', map { "\$$_" } @params);
            push @out, "defun $name($plist)";
            $i++;
            next;
        }

        if ($line =~ /^if\s+(.+)\s+then$/) {
            push @stack, { kind => 'if', elif_count => 0 };
            push @out, 'if ' . maybe_normalize_light_expr($1);
            $i++;
            next;
        }

        if ($line =~ /^elif\s+(.+)\s+then$/ && @stack && $stack[-1]{kind} eq 'if') {
            $stack[-1]{elif_count}++;
            push @out, 'else';
            push @out, 'if ' . maybe_normalize_light_expr($1);
            $i++;
            next;
        }

        if ($line =~ /^while\s+(.+)\s+do$/) {
            push @stack, { kind => 'while' };
            push @out, 'while ' . maybe_normalize_light_expr($1);
            $i++;
            next;
        }

        if ($line =~ /^foreach\s+($LIGHT_IDENT_RE)\s+in\s+(.+)\s+do$/) {
            my ($var, $expr) = ($1, $2);
            $tmp_id++;
            my $tmp = "__foreach_$tmp_id";
            push @out, "set \@$tmp = " . maybe_normalize_light_expr($expr);
            push @out, "foreach \$$var \@$tmp";
            push @stack, { kind => 'foreach' };
            $i++;
            next;
        }

        if ($line =~ /^(let|def)\s+($LIGHT_IDENT_RE)\s*=\s*fun\s*\[([^\]]*)\]\s+do$/) {
            my ($kw, $var, $raw_params) = ($1, $2, $3 // '');
            my @params = parse_light_param_list($raw_params, 'fun');
            my ($body_raw, $next_i) = collect_light_do_block($lines_ref, $i + 1, 'fun');
            my $body_norm = normalize_light_program($body_raw);
            my $fun_name = '__fun_block_' . (++$light_fun_block_seq);
            my $plist = join(', ', map { "\$$_" } @params);
            push @out, "defun $fun_name($plist)";
            push @out, @$body_norm;
            push @out, 'end';
            push @out, "$kw \$$var = make-fun-ref(" . light_escape_string($fun_name) . ")";
            $i = $next_i;
            next;
        }

        if ($line =~ /^($LIGHT_IDENT_RE)\s*=\s*fun\s*\[([^\]]*)\]\s+do$/) {
            my ($var, $raw_params) = ($1, $2 // '');
            my @params = parse_light_param_list($raw_params, 'fun');
            my ($body_raw, $next_i) = collect_light_do_block($lines_ref, $i + 1, 'fun');
            my $body_norm = normalize_light_program($body_raw);
            my $fun_name = '__fun_block_' . (++$light_fun_block_seq);
            my $plist = join(', ', map { "\$$_" } @params);
            push @out, "defun $fun_name($plist)";
            push @out, @$body_norm;
            push @out, 'end';
            push @out, "set \$$var = make-fun-ref(" . light_escape_string($fun_name) . ")";
            $i = $next_i;
            next;
        }

        if ($line eq 'end') {
            if (@stack && $stack[-1]{kind} eq 'if') {
                my $meta = pop @stack;
                push @out, 'end';
                push @out, ('end') x ($meta->{elif_count} // 0);
                $i++;
                next;
            }
            pop @stack if @stack;
            push @out, 'end';
            $i++;
            next;
        }

        if ($line =~ /^return(?:\s+(.+))?$/) {
            my $expr = defined($1) ? $1 : '';
            if ($expr =~ /\S/) {
                push @out, 'return(' . maybe_normalize_light_expr($expr) . ')';
            } else {
                push @out, 'return()';
            }
            $i++;
            next;
        }

        if ($line eq 'break' || $line eq 'continue' || $line eq 'else') {
            push @out, $line;
            $i++;
            next;
        }

        if ($line =~ /^(let|def)\s+($LIGHT_IDENT_RE)\s*=\s*(.+)$/) {
            push @out, "$1 \$$2 = " . maybe_normalize_light_expr($3);
            $i++;
            next;
        }

        if ($line =~ /^($LIGHT_IDENT_RE)\s*\[\s*(.+)\s*\]\s*=\s*(.+)$/) {
            my ($target, $idx, $value) = ($1, $2, $3);
            push @out, 'set-index('
                . maybe_normalize_light_expr($target) . ', '
                . maybe_normalize_light_expr($idx) . ', '
                . maybe_normalize_light_expr($value) . ')';
            $i++;
            next;
        }

        if ($line =~ /^($LIGHT_IDENT_RE)\s*=\s*(.+)$/) {
            push @out, "set \$$1 = " . maybe_normalize_light_expr($2);
            $i++;
            next;
        }

        if ($line =~ /^($LIGHT_IDENT_RE)\s+(.+)$/) {
            my ($head, $tail) = ($1, $2);
            if ($head !~ /^(if|elif|else|while|foreach|def|let|defun|fun|return|break|continue|end|alias|global|when|unless|switch|case|fori|set|rec|sub|defn)$/) {
                my $candidate = "$head($tail)";
                if ($candidate !~ /[\$\@\%]/ && $candidate !~ /[A-Za-z_][A-Za-z0-9_]*-[A-Za-z0-9_]/ && $candidate !~ /[A-Za-z_][A-Za-z0-9_]*\/[A-Za-z_][A-Za-z0-9_]*\s*\(/ && $candidate !~ /\b(?:true|false)\s*\(/ && $candidate !~ /\\/) {
                    push @out, maybe_normalize_light_expr($candidate);
                    $i++;
                    next;
                }
            }
        }

        if ($line =~ /^($LIGHT_IDENT_RE)\s*\((.*)\)$/) {
            # Keep legacy calls untouched when they clearly use legacy-only forms.
            # This limits light normalization to call statements that are safe to lower.
            if ($line !~ /[\$\@\%]/ && $line !~ /[A-Za-z_][A-Za-z0-9_]*-[A-Za-z0-9_]/ && $line !~ /[A-Za-z_][A-Za-z0-9_]*\/[A-Za-z_][A-Za-z0-9_]*\s*\(/ && $line !~ /\b(?:true|false)\s*\(/ && $line !~ /\\/) {
                push @out, maybe_normalize_light_expr($line);
                $i++;
                next;
            }
        }

        push @out, $raw;
        $i++;
    }

    return \@out;
}

# Evaluate a single expression (recursive for function calls)
sub eval_expr {
    my ($expr) = @_;
    $expr =~ s/^\s+//; $expr =~ s/\s+$//;

    if ($expr eq 'nil') {
        return undef;
    }

    # String literal (with $var interpolation)
    if ($expr =~ /^"((?:\\.|[^"\\])*)"$/) {
        return parse_string_literal($1);
    }

    # Number
    if ($expr =~ /^-?\d+(\.\d+)?$/) {
        return $expr + 0;
    }

    # Variable
    if ($expr =~ /^\$($MODULE_NAME_RE)\/($SYMBOL_NAME_RE)$/) {
        my ($module, $name) = ($1, $2);
        if (is_global_name($name)) {
            require_declared_global($name, "expression", 'read');
            return $globals{$name};
        }
        die "Invalid local variable name '\$$name' (locals must be lowercase)\n"
            unless is_local_name($name);
        my (undef, $value) = local_var_lookup($module, $name);
        return $value;
    }
    if ($expr =~ /^\$($SYMBOL_NAME_RE)$/) {
        my $name = $1;
        if (is_global_name($name)) {
            require_declared_global($name, "expression", 'read');
            return $globals{$name};
        }
        die "Invalid local variable name '\$$name' (locals must be lowercase)\n"
            unless is_local_name($name);
        my ($found, $value) = local_var_lookup($current_module, $name);
        return $found ? $value : $globals{$name};
    }

    # Array variable
    if ($expr =~ /^\@($MODULE_NAME_RE)\/($SYMBOL_NAME_RE)$/) {
        my ($module, $name) = ($1, $2);
        if (is_global_name($name)) {
            require_declared_global($name, "expression", 'read');
            return $global_arrays{$name} // [];
        }
        die "Invalid local array name '\@$name' (locals must be lowercase)\n"
            unless is_local_name($name);
        return module_arrays_ref($module)->{$name} // [];
    }
    if ($expr =~ /^\@($SYMBOL_NAME_RE)$/) {
        my $name = $1;
        if (is_global_name($name)) {
            require_declared_global($name, "expression", 'read');
            return $global_arrays{$name} // [];
        }
        die "Invalid local array name '\@$name' (locals must be lowercase)\n"
            unless is_local_name($name);
        return module_arrays_ref($current_module)->{$name} // [];
    }

    # Dict variable
    if ($expr =~ /^\%($MODULE_NAME_RE)\/($SYMBOL_NAME_RE)$/) {
        my ($module, $name) = ($1, $2);
        if (is_global_name($name)) {
            require_declared_global($name, "expression", 'read');
            return $global_dicts{$name} // {};
        }
        die "Invalid local dict name '\%$name' (locals must be lowercase)\n"
            unless is_local_name($name);
        return module_dicts_ref($module)->{$name} // {};
    }
    if ($expr =~ /^\%($SYMBOL_NAME_RE)$/) {
        my $name = $1;
        if (is_global_name($name)) {
            require_declared_global($name, "expression", 'read');
            return $global_dicts{$name} // {};
        }
        die "Invalid local dict name '\%$name' (locals must be lowercase)\n"
            unless is_local_name($name);
        return module_dicts_ref($current_module)->{$name} // {};
    }

    # Vector literal: [a, b, c]
    if ($expr =~ /^\[(.*)?\]$/) {
        my $inner = $1 // '';
        my @items = parse_arglist($inner);
        return [map { eval_expr($_) } @items];
    }

    # Dict literal: {key: val, key2: val2}
    if ($expr =~ /^\{(.*)\}$/) {
        my $inner = $1;
        my $lambda = maybe_parse_lambda_expr($inner, 'lambda');
        return $lambda if defined $lambda;
        my %h;
        for my $pair (parse_arglist($inner)) {
            $pair =~ s/^\s+//; $pair =~ s/\s+$//;
            my ($kexpr, $vexpr) = split_dict_pair($pair);
            die "Bad dict entry: '$pair'\n" unless defined $kexpr && defined $vexpr;
            $kexpr =~ s/^\s+//; $kexpr =~ s/\s+$//;
            $vexpr =~ s/^\s+//; $vexpr =~ s/\s+$//;
            my $key;
            if ($kexpr =~ /^$SYMBOL_NAME_RE$/) {
                $key = $kexpr;
            } else {
                my $kval = eval_expr($kexpr);
                $key = defined $kval ? "$kval" : '';
            }
            $h{$key} = eval_expr($vexpr);
        }
        return \%h;
    }

    # Regex literal:  #"pattern"
    if ($expr =~ /^#"(.*)"$/) {
        return qr/$1/;
    }

    # Function call:  func-name( args... )
    if ($expr =~ /^($SYMBOL_NAME_RE(?:\/$SYMBOL_NAME_RE)?)\s*\((.*)?\)\s*$/) {
        my $fname = $1;
        my $raw_args = $2 // '';
        if ($fname eq 'fun') {
            return parse_lambda_expr($raw_args, 'fun');
        }
        my @args = parse_arglist($raw_args);
        my @evaled = map { eval_expr($_) } @args;

        if ($fname eq 'print') {
            my $last = @evaled > 1 ? $evaled[-1] : 0;
            my $to_stderr = $last && $last eq '1' && @evaled > 1;
            my @parts = $to_stderr ? @evaled[0..$#evaled-1] : @evaled;
            my $out = join('', map { $_ // '' } @parts);
            if ($to_stderr) {
                print STDERR $out, "\n";
            } else {
                print $out, "\n";
            }
            return $out;
        }

        my ($target_module, $sub_name) = resolve_sub_target($fname);
        if (defined $target_module) {
            my $sub = module_subs_ref($target_module)->{$sub_name};
            my $call_id = "$target_module/$sub_name";
            if ($active_calls{$call_id}) {
                die with_line_context("recursion is not allowed for function '$sub_name'; declare it with rec")
                    unless $sub->{recursive};
            }
            my $frames = module_var_frames_ref($target_module);
            push @$frames, {};
            push @call_stack, $call_id;
            $active_calls{$call_id}++;
            my $frame = $frames->[-1];
            my $ret;
            my $ok = eval {
                local $call_depth = $call_depth + 1;
                local $returning = 0;
                local $current_module = $target_module;
                for my $idx (0 .. $#{$sub->{params}}) {
                    $frame->{$sub->{params}[$idx]} = $evaled[$idx];
                }
                delete $frame->{'_return'};
                my $body = $sub->{body_nodes} // $sub->{body} // [];
                run_lines($body);
                $ret = $frame->{'_return'};
                1;
            };
            my $err = $@;
            pop @call_stack;
            $active_calls{$call_id}--;
            delete $active_calls{$call_id} unless $active_calls{$call_id};
            pop @$frames;
            die $err unless $ok;
            return $ret;
        }

        if (exists $builtins{$fname}) {
            my $result = eval { $builtins{$fname}->(@evaled) };
            return $result unless $@;
            die with_line_context($@);
        }

        my ($found_fn, $fn_value) = local_var_lookup($current_module, $fname);
        if ($found_fn && is_slup_lambda($fn_value)) {
            return invoke_lambda($fn_value, @evaled);
        }

        die with_line_context("Unknown function: $fname");
    }

    die with_line_context("Cannot evaluate expression: '$expr'");
}

# Split a comma-separated argument list, respecting parentheses and quotes
sub parse_arglist {
    my ($str) = @_;
    my @args;
    my $depth = 0;
    my $in_quote = 0;
    my $escaped = 0;
    my $current = '';

    for my $ch (split //, $str) {
        if ($in_quote && $escaped) {
            $escaped = 0;
            $current .= $ch;
        } elsif ($in_quote && $ch eq '\\') {
            $escaped = 1;
            $current .= $ch;
        } elsif ($ch eq '"') {
            $in_quote = !$in_quote;
            $current .= $ch;
        } elsif ($in_quote) {
            $current .= $ch;
        } elsif ($ch eq '(' || $ch eq '[' || $ch eq '{') {
            $depth++;
            $current .= $ch;
        } elsif ($ch eq ')' || $ch eq ']' || $ch eq '}') {
            $depth--;
            $current .= $ch;
        } elsif ($ch eq ',' && $depth == 0) {
            push @args, $current;
            $current = '';
        } else {
            $current .= $ch;
        }
    }
    die "Unterminated string in argument list: '$str'\n" if $in_quote;
    die "Unbalanced brackets in argument list: '$str'\n" if $depth != 0;
    push @args, $current if $current =~ /\S/;
    return @args;
}

# ============================================================
#  Execution engine (processes a list of lines)
# ============================================================

sub compile_program {
    my ($lines_ref) = @_;
    my $normalized = normalize_light_program($lines_ref);
    my ($nodes, $next, $term) = compile_block($normalized, 0, 0);
    if (defined $term) {
        my $line = $next;
        die "else without matching if on line $line\n" if $term eq 'else';
        die "end without matching block on line $line\n";
    }
    return $nodes;
}

sub compile_block {
    my ($lines_ref, $start, $allow_else) = @_;
    my @nodes;
    my $i = $start;

    while ($i < scalar @$lines_ref) {
        my $line = $lines_ref->[$i];
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;

        if ($line eq '' || $line =~ /^#/) {
            $i++;
            next;
        }

        if ($line =~ /^else\b/) {
            if ($allow_else) {
                return (\@nodes, $i + 1, 'else');
            }
            die "else without matching if on line " . ($i + 1) . "\n";
        }
        if ($line =~ /^end\b/) {
            return (\@nodes, $i + 1, 'end');
        }

        if ($line =~ /^global\s+\$($SYMBOL_NAME_RE)(?:\s+(.+))?$/) {
            push @nodes, {
                kind => 'global_decl',
                line => $i + 1,
                name => $1,
                raw_mod => $2,
            };
            $i++;
            next;
        }

        if ($line =~ /^(?:set|def|let)\s+\$($SYMBOL_NAME_RE)\s*=\s*(.+)$/) {
            push @nodes, {
                kind => 'set_scalar',
                line => $i + 1,
                var => $1,
                expr => $2,
            };
            $i++;
            next;
        }

        if ($line =~ /^\$($SYMBOL_NAME_RE)\s*=\s*(.+)$/) {
            push @nodes, {
                kind => 'assign_global',
                line => $i + 1,
                var => $1,
                expr => $2,
            };
            $i++;
            next;
        }

        if ($line =~ /^(?:set|def|let)\s+\@($SYMBOL_NAME_RE)\s*=\s*(.+)$/) {
            push @nodes, {
                kind => 'set_array',
                line => $i + 1,
                var => $1,
                expr => $2,
            };
            $i++;
            next;
        }

        if ($line =~ /^(?:set|def|let)\s+\%($SYMBOL_NAME_RE)\s*=\s*(.+)$/) {
            push @nodes, {
                kind => 'set_dict',
                line => $i + 1,
                var => $1,
                expr => $2,
            };
            $i++;
            next;
        }

        if ($line =~ /^return\s*\((.*)\)\s*$/) {
            push @nodes, {
                kind => 'return',
                line => $i + 1,
                raw => $1 // '',
            };
            $i++;
            next;
        }

        if ($line =~ /^if\s+(.+)$/) {
            my $start_line = $i + 1;
            my $cond = $1;
            my ($true_nodes, $next_i, $term) = compile_block($lines_ref, $i + 1, 1);
            die "if without matching end on line $start_line\n" unless defined $term;
            my $false_nodes = [];
            if ($term eq 'else') {
                my ($f_nodes, $after_false, $term2) = compile_block($lines_ref, $next_i, 0);
                die "if without matching end on line $start_line\n" unless defined $term2 && $term2 eq 'end';
                $false_nodes = $f_nodes;
                $i = $after_false;
            } elsif ($term eq 'end') {
                $i = $next_i;
            } else {
                die "if without matching end on line $start_line\n";
            }
            push @nodes, {
                kind => 'if',
                line => $start_line,
                cond => $cond,
                true_body => $true_nodes,
                false_body => $false_nodes,
            };
            next;
        }

        if ($line =~ /^when\s+(.+)$/) {
            my $start_line = $i + 1;
            my $cond = $1;
            my ($true_nodes, $next_i, $term) = compile_block($lines_ref, $i + 1, 1);
            die "when without matching end on line $start_line\n" unless defined $term;
            my $false_nodes = [];
            if ($term eq 'else') {
                my ($f_nodes, $after_false, $term2) = compile_block($lines_ref, $next_i, 0);
                die "when without matching end on line $start_line\n" unless defined $term2 && $term2 eq 'end';
                $false_nodes = $f_nodes;
                $i = $after_false;
            } elsif ($term eq 'end') {
                $i = $next_i;
            } else {
                die "when without matching end on line $start_line\n";
            }
            push @nodes, {
                kind => 'when',
                line => $start_line,
                cond => $cond,
                true_body => $true_nodes,
                false_body => $false_nodes,
            };
            next;
        }

        if ($line =~ /^unless\s+(.+)$/) {
            my $start_line = $i + 1;
            my $cond = $1;
            my ($true_nodes, $next_i, $term) = compile_block($lines_ref, $i + 1, 1);
            die "unless without matching end on line $start_line\n" unless defined $term;
            my $false_nodes = [];
            if ($term eq 'else') {
                my ($f_nodes, $after_false, $term2) = compile_block($lines_ref, $next_i, 0);
                die "unless without matching end on line $start_line\n" unless defined $term2 && $term2 eq 'end';
                $false_nodes = $f_nodes;
                $i = $after_false;
            } elsif ($term eq 'end') {
                $i = $next_i;
            } else {
                die "unless without matching end on line $start_line\n";
            }
            push @nodes, {
                kind => 'unless',
                line => $start_line,
                cond => $cond,
                true_body => $true_nodes,
                false_body => $false_nodes,
            };
            next;
        }

        if ($line =~ /^while\s+(.+)$/) {
            my $start_line = $i + 1;
            my $cond = $1;
            my ($body_nodes, $next_i, $term) = compile_block($lines_ref, $i + 1, 0);
            die "while without matching end on line $start_line\n" unless defined $term && $term eq 'end';
            push @nodes, {
                kind => 'while',
                line => $start_line,
                cond => $cond,
                body => $body_nodes,
            };
            $i = $next_i;
            next;
        }

        if ($line =~ /^(rec|defun)\s+($SYMBOL_NAME_RE)\s*\(([^)]*)\)$/) {
            my $start_line = $i + 1;
            my $kind = $1;
            my $name = $2;
            my $raw_params = $3 // '';
            my @params = grep { $_ ne '' } map {
                my $p = $_;
                $p =~ s/^\s*\$//;
                $p =~ s/^\s+//;
                $p =~ s/\s+$//;
                die "Invalid parameter name '\$$p' (locals must be lowercase)\n"
                    unless is_local_name($p);
                $p;
            } split /,/, $raw_params;

            my ($body_nodes, $next_i, $term) = compile_block($lines_ref, $i + 1, 0);
            die "$kind without matching end on line $start_line\n" unless defined $term && $term eq 'end';
            push @nodes, {
                kind => 'sub_def',
                line => $start_line,
                name => $name,
                params => \@params,
                body => $body_nodes,
                recursive => ($kind eq 'rec' ? 1 : 0),
            };
            $i = $next_i;
            next;
        }

        if ($line =~ /^alias\s+($SYMBOL_NAME_RE)\s*=\s*($SYMBOL_NAME_RE(?:\/$SYMBOL_NAME_RE)?)$/) {
            push @nodes, {
                kind => 'alias',
                line => $i + 1,
                new => $1,
                old => $2,
            };
            $i++;
            next;
        }

        if ($line =~ /^foreach\s+\$($SYMBOL_NAME_RE)\s+\@((?:$MODULE_NAME_RE\/)?$SYMBOL_NAME_RE)$/) {
            my $start_line = $i + 1;
            my ($body_nodes, $next_i, $term) = compile_block($lines_ref, $i + 1, 0);
            die "foreach without matching end on line $start_line\n" unless defined $term && $term eq 'end';
            push @nodes, {
                kind => 'foreach',
                line => $start_line,
                var => $1,
                arrname => $2,
                body => $body_nodes,
            };
            $i = $next_i;
            next;
        }

        if ($line eq 'break') {
            push @nodes, {
                kind => 'break',
                line => $i + 1,
            };
            $i++;
            next;
        }

        if ($line eq 'continue') {
            push @nodes, {
                kind => 'continue',
                line => $i + 1,
            };
            $i++;
            next;
        }

        if ($line =~ /^$SYMBOL_NAME_RE(?:\/$SYMBOL_NAME_RE)?\s*\(/) {
            push @nodes, {
                kind => 'call',
                line => $i + 1,
                expr => $line,
            };
            $i++;
            next;
        }

        die "Syntax error on line " . ($i + 1) . ": $line\n";
    }

    return (\@nodes, $i, undef);
}

sub run_nodes {
    my ($nodes_ref) = @_;
    for my $node (@$nodes_ref) {
        exec_node($node);
        last if $returning || $breaking || $continuing;
    }
}

sub run_lines {
    my ($program_ref) = @_;
    if (@$program_ref && ref($program_ref->[0]) eq 'HASH') {
        run_nodes($program_ref);
        return;
    }
    my $nodes = compile_program($program_ref);
    run_nodes($nodes);
}

sub exec_node {
    my ($node) = @_;
    my $line_no = $node->{line};
    my $kind = $node->{kind};
    local $active_line_no = $line_no;

    if ($kind eq 'global_decl') {
        my $where = "line $line_no";
        my $spec = parse_global_decl_modifier($node->{raw_mod});
        declare_global_spec($node->{name}, $spec, $where);
        if ($spec->{has_default} && !exists $globals{$node->{name}}) {
            $globals{$node->{name}} = eval_expr($spec->{default_expr});
        }
        return;
    }

    if ($kind eq 'set_scalar') {
        my ($var, $expr) = ($node->{var}, $node->{expr});
        if (is_global_name($var)) {
            require_declared_global($var, "line $line_no", 'assignment');
            $globals{$var} = eval_expr($expr);
        } elsif (is_local_name($var)) {
            local_var_set($current_module, $var, eval_expr($expr));
        } else {
            die "Invalid local variable name '\$$var' (locals must be lowercase)\n";
        }
        return;
    }

    if ($kind eq 'assign_global') {
        my ($var, $expr) = ($node->{var}, $node->{expr});
        die "Global names must be uppercase: '\$$var'\n" unless is_global_name($var);
        require_declared_global($var, "line $line_no", 'assignment');
        $globals{$var} = eval_expr($expr);
        return;
    }

    if ($kind eq 'set_array') {
        my ($var, $expr) = ($node->{var}, $node->{expr});
        if (is_global_name($var)) {
            require_declared_global($var, "line $line_no", 'assignment');
            $global_arrays{$var} = eval_expr($expr);
        } elsif (is_local_name($var)) {
            module_arrays_ref($current_module)->{$var} = eval_expr($expr);
        } else {
            die "Invalid local array name '\@$var' (locals must be lowercase)\n";
        }
        return;
    }

    if ($kind eq 'set_dict') {
        my ($var, $expr) = ($node->{var}, $node->{expr});
        if (is_global_name($var)) {
            require_declared_global($var, "line $line_no", 'assignment');
            $global_dicts{$var} = eval_expr($expr);
        } elsif (is_local_name($var)) {
            module_dicts_ref($current_module)->{$var} = eval_expr($expr);
        } else {
            die "Invalid local dict name '\%$var' (locals must be lowercase)\n";
        }
        return;
    }

    if ($kind eq 'return') {
        die "return outside function on line $line_no\n" if $call_depth <= 0;
        my $raw = $node->{raw} // '';
        if ($raw =~ /\S/) {
            local_var_set($current_module, '_return', eval_expr($raw));
        } else {
            local_var_set($current_module, '_return', undef);
        }
        $returning = 1;
        return;
    }

    if ($kind eq 'if') {
        my $cond = eval_expr($node->{cond});
        my $truthy = $cond && $cond ne '0' && $cond ne '';
        if ($truthy) {
            run_lines($node->{true_body});
        } else {
            run_lines($node->{false_body});
        }
        return;
    }

    if ($kind eq 'when') {
        my $cond = eval_expr($node->{cond});
        my $truthy = $cond && $cond ne '0' && $cond ne '';
        if ($truthy) {
            run_lines($node->{true_body});
        } else {
            run_lines($node->{false_body});
        }
        return;
    }

    if ($kind eq 'unless') {
        my $cond = eval_expr($node->{cond});
        my $truthy = $cond && $cond ne '0' && $cond ne '';
        if (!$truthy) {
            run_lines($node->{true_body});
        } else {
            run_lines($node->{false_body});
        }
        return;
    }

    if ($kind eq 'while') {
        local $loop_depth = $loop_depth + 1;
        while (1) {
            my $cond = eval_expr($node->{cond});
            my $truthy = $cond && $cond ne '0' && $cond ne '';
            last unless $truthy;
            run_lines($node->{body});
            last if $returning;
            if ($breaking) {
                $breaking = 0;
                last;
            }
            if ($continuing) {
                $continuing = 0;
                next;
            }
        }
        return;
    }

    if ($kind eq 'sub_def') {
        module_subs_ref($current_module)->{$node->{name}} = {
            params => $node->{params},
            body => $node->{body},
            recursive => $node->{recursive} ? 1 : 0,
        };
        return;
    }

    if ($kind eq 'alias') {
        my ($new, $old) = ($node->{new}, $node->{old});
        if (exists $builtins{$old}) {
            $builtins{$new} = $builtins{$old};
        } else {
            my ($target_module, $sub_name) = resolve_sub_target($old);
            if (defined $target_module) {
                module_subs_ref($current_module)->{$new} = module_subs_ref($target_module)->{$sub_name};
            } else {
                die "alias: unknown function '$old'\n";
            }
        }
        return;
    }

    if ($kind eq 'foreach') {
        my ($var, $arrname) = ($node->{var}, $node->{arrname});
        if (!is_global_name($var) && !is_local_name($var)) {
            die "Invalid local variable name '\$$var' (locals must be lowercase)\n";
        }
        my $arr;
        if ($arrname =~ /^($MODULE_NAME_RE)\/($SYMBOL_NAME_RE)$/) {
            my ($module, $name) = ($1, $2);
            if (is_global_name($name)) {
                require_declared_global($name, "line $line_no", 'read');
                $arr = $global_arrays{$name} // [];
            } else {
                die "Invalid local array name '\@$name' (locals must be lowercase)\n"
                    unless is_local_name($name);
                $arr = module_arrays_ref($module)->{$name} // [];
            }
        } else {
            if (is_global_name($arrname)) {
                require_declared_global($arrname, "line $line_no", 'read');
                $arr = $global_arrays{$arrname} // [];
            } else {
                die "Invalid local array name '\@$arrname' (locals must be lowercase)\n"
                    unless is_local_name($arrname);
                $arr = module_arrays_ref($current_module)->{$arrname} // [];
            }
        }

        for my $elem (@$arr) {
            if (is_global_name($var)) {
                require_declared_global($var, "line $line_no", 'assignment');
                $globals{$var} = $elem;
            } else {
                local_var_set($current_module, $var, $elem);
            }
            run_lines($node->{body});
            last if $returning;
            if ($breaking) {
                $breaking = 0;
                last;
            }
            if ($continuing) {
                $continuing = 0;
                next;
            }
        }
        return;
    }

    if ($kind eq 'break') {
        die "break outside loop on line $line_no\n" if $loop_depth <= 0;
        $breaking = 1;
        return;
    }

    if ($kind eq 'continue') {
        die "continue outside loop on line $line_no\n" if $loop_depth <= 0;
        $continuing = 1;
        return;
    }

    if ($kind eq 'call') {
        eval_expr($node->{expr});
        return;
    }

    die "Unknown node kind '$kind'\n";
}

# ============================================================
#  Main – read from file or STDIN
# ============================================================

my @program;
my $check_mode = 0;
while (@ARGV && $ARGV[0] =~ /^--/) {
    if ($ARGV[0] eq '--check') {
        $check_mode = 1;
        shift @ARGV;
        next;
    }
    if ($ARGV[0] eq '--strict-globals') {
        $strict_globals_mode = 1;
        shift @ARGV;
        next;
    }
    die "Unknown option: $ARGV[0]\n";
}

if ($check_mode) {
    die "Usage: slup.pl --check <file>\n" unless @ARGV;
    my $ok = run_static_check($ARGV[0]);
    exit($ok ? 0 : 1);
}

if ($strict_globals_mode && @ARGV) {
    my $ok = run_static_check($ARGV[0]);
    exit 1 unless $ok;
}

if (@ARGV) {
    open my $fh, '<', $ARGV[0] or die "Cannot open $ARGV[0]: $!\n";
    @program = <$fh>;
    close $fh;
} else {
    @program = <STDIN>;
}

chomp @program;

# Populate script args: $PATH, $ARG1..$ARGN, @ARGS
if (@ARGV) {
    require File::Basename;
    $module_dirs{$MAIN_MODULE} = File::Basename::dirname($ARGV[0]);

    predeclare_global_if_missing('PATH');
    $globals{'PATH'} = $ARGV[0];
    for my $i (1 .. $#ARGV) {
        predeclare_global_if_missing("ARG$i");
        $globals{"ARG$i"} = $ARGV[$i];
    }
    predeclare_global_if_missing('ARGS');
    $global_arrays{'ARGS'} = [@ARGV[1 .. $#ARGV]];
} else {
    predeclare_global_if_missing('ARGS');
    $global_arrays{'ARGS'} = [];
}

predeclare_global_if_missing('ENV');
$global_dicts{'ENV'} = { %ENV };

my $program_nodes = compile_program(\@program);
run_lines($program_nodes);
validate_required_globals_runtime() if $strict_globals_mode;
