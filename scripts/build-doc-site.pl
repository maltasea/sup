#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename qw(dirname);
use File::Path qw(make_path);

my $in_path = $ARGV[0] // 'docs/language-guide.md';
my $out_path = $ARGV[1] // 'docs/site/index.html';

open my $in, '<', $in_path or die "cannot read $in_path: $!";
local $/;
my $md = <$in>;
close $in;

sub esc_html {
    my ($s) = @_;
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    return $s;
}

sub esc_attr {
    my ($s) = @_;
    $s = esc_html($s);
    $s =~ s/"/&quot;/g;
    return $s;
}

sub fmt_inline {
    my ($text) = @_;
    my @parts = split /(`[^`]*`)/, $text;
    my @out;
    for my $part (@parts) {
        next if !defined $part || $part eq '';
        if ($part =~ /^`([^`]*)`$/) {
            push @out, '<code>' . esc_html($1) . '</code>';
        } else {
            my $p = esc_html($part);
            $p =~ s/\*\*([^*]+)\*\*/<strong>$1<\/strong>/g;
            $p =~ s/\*([^*]+)\*/<em>$1<\/em>/g;
            push @out, $p;
        }
    }
    return join('', @out);
}

sub slugify {
    my ($text, $seen) = @_;
    my $slug = lc $text;
    $slug =~ s/[^a-z0-9]+/-/g;
    $slug =~ s/^-+//;
    $slug =~ s/-+$//;
    $slug = 'section' if $slug eq '';
    my $base = $slug;
    my $i = 2;
    while ($seen->{$slug}) {
        $slug = $base . '-' . $i;
        $i++;
    }
    $seen->{$slug} = 1;
    return $slug;
}

my @lines = split /\n/, $md;
push @lines, undef;

my $html = '';
my $title = 'Esca Language Guide';
my $first_h1_seen = 0;
my @toc;
my %slug_seen;
my $in_code = 0;
my $code_lang = '';
my @code_buf;
my $list_type = '';
my @para_buf;

sub flush_para {
    my ($html_ref, $buf_ref) = @_;
    return if !@$buf_ref;
    my $text = join(' ', map { s/^\s+//r =~ s/\s+$//r } @$buf_ref);
    $$html_ref .= '<p>' . fmt_inline($text) . "</p>\n";
    @$buf_ref = ();
}

sub close_list {
    my ($html_ref, $list_type_ref) = @_;
    return if $$list_type_ref eq '';
    $$html_ref .= "</$$list_type_ref>\n";
    $$list_type_ref = '';
}

for my $line (@lines) {
    if ($in_code) {
        if (!defined $line || $line =~ /^```/) {
            my $lang_attr = $code_lang ne '' ? ' class="lang-' . esc_attr($code_lang) . '"' : '';
            $html .= '<pre><code' . $lang_attr . '>' . esc_html(join("\n", @code_buf)) . "</code></pre>\n";
            $in_code = 0;
            $code_lang = '';
            @code_buf = ();
            next if !defined $line;
            next;
        }
        push @code_buf, $line;
        next;
    }

    if (!defined $line) {
        flush_para(\$html, \@para_buf);
        close_list(\$html, \$list_type);
        last;
    }

    if ($line =~ /^```([A-Za-z0-9_-]+)?\s*$/) {
        flush_para(\$html, \@para_buf);
        close_list(\$html, \$list_type);
        $in_code = 1;
        $code_lang = defined $1 ? $1 : '';
        @code_buf = ();
        next;
    }

    if ($line =~ /^\s*$/) {
        flush_para(\$html, \@para_buf);
        close_list(\$html, \$list_type);
        next;
    }

    if ($line =~ /^(#{1,6})\s+(.+?)\s*$/) {
        flush_para(\$html, \@para_buf);
        close_list(\$html, \$list_type);
        my $level = length($1);
        my $text = $2;
        my $is_first_h1 = ($level == 1 && !$first_h1_seen);
        my $id = slugify($text, \%slug_seen);
        if ($is_first_h1) {
            $title = $text;
            $first_h1_seen = 1;
            next;
        }
        if ($level == 2 || $level == 3) {
            push @toc, { level => $level, text => $text, id => $id };
        }
        $html .= sprintf('<h%d id="%s">%s</h%d>', $level, esc_attr($id), fmt_inline($text), $level) . "\n";
        next;
    }

    if ($line =~ /^\s*-\s+(.+?)\s*$/) {
        flush_para(\$html, \@para_buf);
        if ($list_type ne 'ul') {
            close_list(\$html, \$list_type);
            $list_type = 'ul';
            $html .= "<ul>\n";
        }
        $html .= '<li>' . fmt_inline($1) . "</li>\n";
        next;
    }

    if ($line =~ /^\s*\d+\.\s+(.+?)\s*$/) {
        flush_para(\$html, \@para_buf);
        if ($list_type ne 'ol') {
            close_list(\$html, \$list_type);
            $list_type = 'ol';
            $html .= "<ol>\n";
        }
        $html .= '<li>' . fmt_inline($1) . "</li>\n";
        next;
    }

    push @para_buf, $line;
}

my $toc_html = "<ul>\n";
for my $item (@toc) {
    my $klass = $item->{level} == 3 ? ' class="toc-sub"' : '';
    $toc_html .= sprintf('  <li%s><a href="#%s">%s</a></li>', $klass, esc_attr($item->{id}), esc_html($item->{text})) . "\n";
}
$toc_html .= "</ul>\n";

my $doc = <<"HTML";
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>@{[esc_html($title)]}</title>
  <meta name="description" content="Esca language learning guide">
  <style>
    :root {
      --bg-1: #fff4de;
      --bg-2: #eaf7ff;
      --panel: #ffffffd9;
      --ink: #1a1f2b;
      --ink-soft: #4f5a6b;
      --accent: #0f766e;
      --accent-2: #c2410c;
      --line: #d8dee8;
      --code-bg: #172030;
      --code-ink: #eff5ff;
      --shadow: 0 18px 44px rgba(15, 23, 42, 0.16);
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: "IBM Plex Sans", "Avenir Next", "Segoe UI", sans-serif;
      color: var(--ink);
      background:
        radial-gradient(1200px 620px at 7% -8%, #ffd89e 0%, transparent 55%),
        radial-gradient(1000px 560px at 96% -12%, #a5d7ff 0%, transparent 52%),
        linear-gradient(135deg, var(--bg-1), var(--bg-2));
      min-height: 100vh;
    }
    .shell {
      width: min(1160px, 94vw);
      margin: 40px auto 56px;
      animation: rise 560ms ease-out both;
    }
    .hero {
      background: linear-gradient(145deg, #ffffff, #fff9ee);
      border: 1px solid #f2dcc2;
      border-radius: 22px;
      padding: 26px 30px;
      box-shadow: var(--shadow);
      position: relative;
      overflow: hidden;
    }
    .hero::after {
      content: "";
      position: absolute;
      right: -80px;
      top: -66px;
      width: 240px;
      height: 240px;
      border-radius: 50%;
      background: radial-gradient(circle at 38% 36%, #ffb45f, #ff8d41);
      opacity: .14;
      pointer-events: none;
    }
    h1 {
      margin: 0 0 6px;
      font-family: "Sora", "Trebuchet MS", sans-serif;
      letter-spacing: -0.02em;
      font-size: clamp(1.8rem, 3.4vw, 2.8rem);
      line-height: 1.1;
    }
    .tagline {
      margin: 0;
      color: var(--ink-soft);
      font-size: 1.03rem;
    }
    .layout {
      display: grid;
      grid-template-columns: 280px 1fr;
      gap: 22px;
      margin-top: 20px;
    }
    .toc, .content {
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 18px;
      box-shadow: var(--shadow);
      backdrop-filter: blur(4px);
    }
    .toc {
      position: sticky;
      top: 16px;
      align-self: start;
      padding: 16px 16px 18px;
    }
    .toc h2 {
      margin: 0 0 10px;
      font-size: 0.95rem;
      text-transform: uppercase;
      letter-spacing: 0.11em;
      color: var(--accent-2);
      font-family: "Sora", "Trebuchet MS", sans-serif;
    }
    .toc ul {
      list-style: none;
      margin: 0;
      padding: 0;
      display: grid;
      gap: 8px;
    }
    .toc a {
      color: #1f2f45;
      text-decoration: none;
      font-size: 0.95rem;
      line-height: 1.25;
      border-left: 3px solid transparent;
      padding-left: 8px;
      transition: border-color .18s ease, color .18s ease, transform .18s ease;
      display: inline-block;
    }
    .toc a:hover {
      color: var(--accent);
      border-left-color: var(--accent);
      transform: translateX(2px);
    }
    .toc-sub a { font-size: 0.9rem; opacity: 0.86; }
    .content {
      padding: 24px 28px 34px;
      overflow: hidden;
    }
    .content h2 {
      margin: 28px 0 10px;
      font-family: "Sora", "Trebuchet MS", sans-serif;
      font-size: 1.42rem;
      color: #0f2038;
    }
    .content h3 {
      margin: 20px 0 8px;
      font-family: "Sora", "Trebuchet MS", sans-serif;
      font-size: 1.16rem;
      color: #153357;
    }
    .content p, .content li {
      color: #273445;
      line-height: 1.6;
      font-size: 1rem;
    }
    .content p {
      margin: 0 0 12px;
    }
    .content ul, .content ol {
      margin: 6px 0 14px 24px;
      padding: 0;
    }
    code {
      font-family: "IBM Plex Mono", "SFMono-Regular", Menlo, monospace;
      background: #edf2f9;
      border: 1px solid #d6e1ef;
      border-radius: 6px;
      padding: 0.08rem 0.35rem;
      font-size: 0.92em;
      color: #14212f;
      white-space: nowrap;
    }
    pre {
      margin: 10px 0 16px;
      padding: 14px 16px;
      border-radius: 14px;
      background: linear-gradient(160deg, #131d2f, #1e2a42);
      border: 1px solid #2a3a59;
      color: var(--code-ink);
      overflow-x: auto;
    }
    pre code {
      background: none;
      border: 0;
      color: inherit;
      padding: 0;
      white-space: pre;
      font-size: 0.92rem;
    }
    \@media (max-width: 940px) {
      .layout { grid-template-columns: 1fr; }
      .toc {
        position: relative;
        top: 0;
      }
      .content { padding: 20px 18px 26px; }
    }
    \@keyframes rise {
      from { opacity: 0; transform: translateY(12px); }
      to { opacity: 1; transform: translateY(0); }
    }
  </style>
</head>
<body>
  <main class="shell">
    <header class="hero">
      <h1>@{[esc_html($title)]}</h1>
      <p class="tagline">A proglang for lazy people.</p>
    </header>
    <section class="layout">
      <aside class="toc">
        <h2>Contents</h2>
        $toc_html
      </aside>
      <article class="content">
        $html
      </article>
    </section>
  </main>
</body>
</html>
HTML

my $out_dir = dirname($out_path);
make_path($out_dir) if !-d $out_dir;
open my $out, '>', $out_path or die "cannot write $out_path: $!";
print {$out} $doc;
close $out;

print "Wrote $out_path from $in_path\n";
