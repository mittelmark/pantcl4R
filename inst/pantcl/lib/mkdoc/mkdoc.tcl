#!/bin/sh
# A Tcl comment, whose contents don't matter \
exec tclsh "$0" "$@"
##############################################################################
#  Author        : Dr. Detlef Groth
#  Created       : Fri Nov 15 10:20:22 2019
#  Last Modified : <230602.2040>
#
#  Description	 : Command line utility and package to extract Markdown documentation 
#                  from programming code if embedded as after comment sequence #' 
#                  manual pages and installation of Tcl files as Tcl modules.
#                  Copy and adaptation of dgw/dgwutils.tcl
#
#  History       : 2019-11-08 version 0.1
#                  2019-11-28 version 0.2
#                  2020-02-26 version 0.3
#	
##############################################################################
#
# Copyright (c) 2019-2022  Dr. Detlef Groth, E-mail: detlef(at)dgroth(dot)de
# 
# This library is free software; you can use, modify, and redistribute it
# for any purpose, provided that existing copyright notices are retained
# in all copies and that this notice is included verbatim in any
# distributions.
# 
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
##############################################################################
#'
#' ---
#' title: mkdoc::mkdoc __PKGVERSION__
#' author: Dr. Detlef Groth, Schwielowsee, Germany
#' documentclass: scrartcl
#' geometry:
#' - top=20mm
#' - right=20mm
#' - left=20mm
#' - bottom=30mm
#' ---
#'
#' ## NAME
#'
#' **mkdoc::mkdoc**  - Tcl package and command line application to extract and format 
#' embedded programming documentation from source code files written in Markdown and 
#' optionally converts them into HTML.
#'
#' ## <a name='toc'></a>TABLE OF CONTENTS
#' 
#'  - [SYNOPSIS](#synopsis)
#'  - [DESCRIPTION](#description)
#'  - [COMMAND](#command)
#'      - [mkdoc::mkdoc](#mkdoc)
#'      - [mkdoc::run](#run)
#'  - [EXAMPLE](#example)
#'  - [BASIC FORMATTING](#format)
#'  - [INSTALLATION](#install)
#'  - [SEE ALSO](#see)
#'  - [CHANGES](#changes)
#'  - [TODO](#todo)
#'  - [AUTHOR](#authors)
#'  - [LICENSE AND COPYRIGHT](#license)
#'
#' ## <a name='synopsis'>SYNOPSIS</a>
#' 
#' Usage as package:
#'
#' ```
#' package require mkdoc::mkdoc
#' mkdoc::mkdoc inputfile outputfile ?-html|-md|-pandoc -css file.css?
#' ```
#'
#' Usage as command line application for extraction of Markdown comments prefixed with `#'`:
#'
#' ```
#' mkdoc inputfile outputfile ?--html|--md|--pandoc --css file.css?
#' ```
#'
#' Usage as command line application for conversion of Markdown to HTML:
#'
#' ```
#' mkdoc inputfile.md outputfile.html ?--css file.css?
#' ```
#'
#' ## <a name='description'>DESCRIPTION</a>
#' 
#' **mkdoc::mkdoc**  extracts embedded Markdown documentation from source code files and  as well converts Markdown output to HTML if desired.
#' The documentation inside the source code must be prefixed with the `#'` character sequence.
#' The file extension of the output file determines the output format. File extensions can bei either `.md` for Markdown output or `.html` for html output. The latter requires the tcllib Markdown extension to be installed. If the file extension of the inputfile is *.md* and file extension of the output files is *.html* there will be simply a conversion from a Markdown to a HTML file.
#'
#' The file `mkdoc.tcl` can be as well directly used as a console application. An explanation on how to do this, is given in the section [Installation](#install).
#'
#' ## <a name='command'>COMMAND</a>
#'
#'  <a name="mkdoc" />
#' **mkdoc::mkdoc** *infile outfile ?-mode -css file.css?*
#' 
#' > Extracts the documentation in Markdown format from *infile* and writes the documentation 
#'    to *outfile* either in Markdown  or HTML format. 
#' 
#' >  - *-infile filename* - file with embedded markdown documentation
#'   - *-outfile filename* -  name of output file extension
#'   - *-html* - (mode) outfile should be a html file, not needed if the outfile extension is html
#'   - *-md* - (mode) outfile should be a Markdown file, not needed if the outfile extension is md
#'   - *-pandoc* - (mode) outfile should be a pandoc Markdown file with YAML header, needed even if the outfile extension is md
#'   - *-css cssfile* if outfile mode is html uses the given *cssfile*
#'     
#' > If the *-mode* flag  (one of -html, -md, -pandoc) is not given, the output format is taken from the file extension of the output file, either *.html* for HTML or *.md* for Markdown format. This deduction from the filetype can be overwritten giving either `-html` or `-md` as command line flags. If as mode `-pandoc` is given, the Markdown markup code as well contains the YAML header.
#'   If infile has the extension .md than conversion to html will be performed, outfile file extension
#'   In this case must be .html. If output is html a *-css* flag can be given to use the given stylesheet file instead of the default style sheet embedded within the mkdoc code.
#'  
#' > Example:
#'
#' > ```
#' package require mkdoc::mkdoc
#' mkdoc::mkdoc mkdoc.tcl mkdoc.html
#' mkdoc::mkdoc mkdoc.tcl mkdoc.rmd -md
#' > ```

package require Tcl 8.4
if {[package provide Markdown] eq ""} {
    package require Markdown
}
package provide mkdoc::mkdoc 0.6.1
package provide mkdoc [package present mkdoc::mkdoc]
namespace eval mkdoc {
    variable mkdocfile [info script]
    variable htmltemplate {
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="generator" content="mkdoc" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="title" content="$document(title)">
  <meta name="author" content="$document(author)">
  <title>$document(title)</title>
$document(style)
</head>
<body>
}

variable htmltitle {
    <div class="title"><h1>$document(title)</h1></div>
    <div class="author"><h3>$document(author)</h3></div>
    <div class="date"><h3>$document(date)</h3></div>
}
variable mdheader {
# $document(title)
    
### $document(author)
    
### $document(date)
}

variable style {
    <style>
    body {
        margin-left: 5%; margin-right: 5%;
        font-family: Palatino, "Palatino Linotype", "Palatino LT STD", "Book Antiqua", Georgia, serif;
    }
pre {
padding-top:	1ex;
padding-bottom:	1ex;
padding-left:	2ex;
padding-right:	1ex;
width:		100%;
color: 		black;
background: 	#ffefdf;
border-top:		1px solid black;
border-bottom:		1px solid black;
font-family: Monaco, Consolas, "Liberation Mono", Menlo, Courier, monospace;

}
pre.synopsis {
    background: #cceeff;
}
pre.code code.tclin {
    background-color: #ffeeee;
}
pre.code code.tclout {
    background-color: #ffffee;
}

code {
    font-family: Consolas, "Liberation Mono", Menlo, Courier, monospace;
}
h1,h2, h3,h4 {
    font-family:	sans-serif;
    background: 	transparent;
}
h1 {
    font-size: 120%;
    text-align: center;
}

h2.author, h2.date {
    text-align: center;
    color: black;
}
h2 {
    font-size: 110%;
}
h3, h4 {
    font-size: 100%
}
div.title h1 {
    font-family:	sans-serif;
    font-size:	120%;
    background: 	transparent;
    text-align:	center;
    color: black;
}
div.author h3, div.date h3 {
    font-family:	sans-serif;
    font-size:	110%;
    background: 	transparent;
    text-align:	center;
    color: black ;
}
h2 {
margin-top: 	1em;
font-family:	sans-serif;
font-size:	110%;
color:		#005A9C;
background: 	transparent;
text-align:		left;
}

h3 {
margin-top: 	1em;
font-family:	sans-serif;
font-size:	100%;
color:		#005A9C;
background: 	transparent;
text-align:		left;
}
</style>
}
} 

proc ::mkdoc::pfirst {varname arglist} {
    upvar $varname x
    set varval $x
    if {[regexp {^-} $varval]} {
        set arglist [linsert $arglist 0 $varval]
        set x [lindex $args end]
        set arglist [lrange $arglist 0 end-1]
    } else {
        set x $varval
    }
    return $arglist
}
# argument parser for procedures
# places all --options or -options in an array given with arrayname
# recognises
# -option2 value -flag1 -flag2 -option2 value
proc ::mkdoc::pargs {arrayname defaults args} {
    upvar $arrayname arga
    array set arga $defaults
    set args {*}$args
    set kindex 0
    set args [lmap i $args { regsub -- {^--} $i "-" }]
    while {[llength $args] > 0} {
        set a [lindex $args 0]
        set args [lrange $args 1 end]
        if {[regexp {^-{1,2}(.+)} $a -> opt]} {
            if {[llength $args] == 0} {
                # odd number - take first key
                set key [lindex $defaults $kindex]
                set arga($key) $opt
            } elseif {([llength $args] > 0 && [regexp -- {^-} [lindex $args 0]]) || [llength $args] == 0} {
                set arga($opt) true
            } elseif {[regexp {^[^-].*} [lindex $args 0] value]} {
                #set opt [lindex $defaults $kindex]
                incr kindex 2
                set arga($opt) $value
                set args [lrange $args 1 end]
            }
        } 
    }
    
}

proc ::mkdoc::getPackageInformation {filename} {
    set basename [file rootname [file tail $filename]]
    if {[file extension $filename] in [list .tm .tcl]} {
        if [catch {open $filename r} infh] {
            puts stderr "Cannot open $filename: $infh"
            exit
        } else {
            while {[gets $infh line] >= 0} {
                # Process line
                if {[regexp {^\s*package\s+provide\s+([^\s]+)\s+([.0-9a-z]+)} $line -> package version]} {
                    return [list name $package version $version basename $basename]
                }
            }
            close $infh
        }
    }
    return [list name "" version "" basename $basename]
}
proc mkdoc::mkdoc {filename outfile args} {
    global quiet
    if {![info exists ::quiet]} {
        set quiet false
    }
    variable mkdocfile
    variable htmltemplate
    variable mdheader
    variable htmltitle
    variable style
    # prepare sorting methods and options
    set dmeths [dict create]
    set methods false
    
    array set pkg [getPackageInformation $filename]
    if {[llength $args] == 1} {
        set args {*}$args
    }
    ::mkdoc::pargs arg [list mode "" css ""] $args
    set mode $arg(mode)
    if {$mode ni [list "" html markdown man pandoc]} {
        set file [file join [file dirname $mkdocfile] ${mode}.tcl]
        lappend ::auto_path [file join [file dirname [info script]] ..]
        catch { package require mkdoc::${mode} }
        if {[lsearch [package names] mkdoc::${mode}] == -1} {
            error "package mkdoc::${mode} for mode $mode does not exist"
        } else {
            mkdoc::$mode $filename $outfile
        } 
        return
    }
    if {[file extension $filename] eq [file extension $outfile]} {
        error "Error: infile and outfile must have different file extensions"
    }
    if {[file extension $filename] eq ".md"} {
        if {[file extension $outfile] ne ".html"} {
            error "For converting Markdown files directly file extension of output file must be .html"
        }
        set mode "html"
        set extract false
    } else {
        set extract true
    }
    if {$mode eq ""} {
        if {[file extension $outfile] eq ".html"} {
            set mode "html"
        } elseif {[file extension $outfile] eq ".md"} {
            set mode "markdown"
        } else {
            error "Unknown output file format, must be either .html or .md"
        }
    } else {
        if {$mode ne "html" && $mode ne "markdown" && $mode ne "md" && $mode ne "pandoc"} {
            error "Unknown mode, must be either -html, -md, -markdown or -pandoc"
        } 
    }
    set markdown ""
    if {$mode eq "html"} {
        if {[package provide Markdown] eq ""} {
            error "Error: For html mode you need package Markdown from tcllib. Download and install tcllib from http://core.tcl.tk"
        } else {
            package require Markdown   
        }
    }
    if [catch {open $filename r} infh] {
        puts stderr "Cannot open $filename: $infh"
        exit
    } else {
        set flag false
        while {[gets $infh line] >= 0} {
            if {$extract} {
                if {[regexp {^\s*#' +#include +"(.*)"} $line -> include]} {
                    if [catch {open $include r} iinfh] {
                        puts stderr "Cannot open $filename: $include"
                        exit 0
                    } else {
                        #set ilines [read $iinfh]
                        while {[gets $iinfh iline] >= 0} {
                            # Process line
                            append markdown "$iline\n"
                        }
                        close $iinfh
                    }
                } elseif {[regexp {^\s*#' ?(.*)} $line -> md]} {
                    append markdown "$md\n"
                }
            } else {
                # simple markdown to html converter
                append markdown "$line\n"
            }
        }
        close $infh
        set titleflag false
        array set document [list title "Documentation [file tail [file rootname $filename]]" author "NN" date  [clock format [clock seconds] -format "%Y-%m-%d"] style $style]
        if {$arg(css) eq ""} {
            set document(style) $style
        } else {
            set document(style) "<link rel='stylesheet' href='$arg(css)' type='text/css'>"
        }
        set mdhtml ""
        set YAML ""
        set indent ""
        set header $htmltemplate
        set lnr 0
        foreach line [split $markdown "\n"] {
            incr lnr 
            if {$lnr < 4 && [regexp {^%} $line]} {
                # pandoc percent properties
                # line 1 title, line 2 author, line 3 date
                if {$lnr == 1} {
                    set document(title) [regsub {^% +} $line ""]
                } elseif {$lnr == 2} {
                    set document(author) [regsub {^% +} $line ""]
                } elseif {$lnr == 3} {
                    set document(date) [regsub {^% +} $line ""]                    
                }
                continue
            }
            # todo document pkgversion and pkgname
            #set line [regsub {__PKGVERSION__} $line [package provide mkdoc::mkdoc]]
            #set line [regsub -all {__PKGNAME__} $line mkdoc::mkdoc]
            if {$titleflag && [regexp {^---} $line]} {
                set titleflag false
                set header [subst -nobackslashes -nocommands $header]
                set htmltitle [subst -nobackslashes -nocommands $htmltitle]
                set mdheader [subst -nobackslashes -nocommands $mdheader]
                append YAML "$line\n"
            } elseif {$titleflag} {
                if {$pkg(name) ne ""} {
                    set line [regsub -all {__PKGNAME__} $line $pkg(name)]
                } 
                if {$pkg(version) ne ""} {
                    set line [regsub -all {__PKGVERSION__} $line $pkg(version)]
                }
                set line [regsub -all {__DATE__} $line [clock format [clock seconds] -format "%Y-%m-%d"]] 
                set line [regsub -all {__BASENAME__} $line $pkg(basename)]
                
                append YAML "$line\n"
                if {[regexp {^\s*([a-z]+): +(.+)} $line -> key value]} {
                    if {$key eq "style"} {
                        set document($key) "<link rel='stylesheet' href='$value' type='text/css'>"
                        if {$arg(css) ne ""} {
                            append document($key) "\n<link rel='stylesheet' href='$arg(css)' type='text/css'>"
                        } 
                    } elseif {$key in [list title date author]} {
                        set document($key) $value
                    }
                }
            } elseif {[regexp {^---} $line] && $lnr < 5} {
                append YAML "$line\n"
                set titleflag true
            } else {
                if {$pkg(name) ne ""} {
                    set line [regsub -all {__PKGNAME__} $line $pkg(name)]
                } 
                if {$pkg(version) ne ""} {
                    set line [regsub -all {__PKGVERSION__} $line $pkg(version)]
                }
                set line [regsub -all {__DATE__} $line [clock format [clock seconds] -format "%Y-%m-%d"]] 
                set line [regsub -all {__BASENAME__} $line $pkg(basename)]
                # sorting code start: collect and sort methods alphabetically
                if {$methods && [regexp {^## <a\s+name} $line]} {
                    set methods false
                    foreach key [lsort [dict keys $dmeths]] {
                        if {[dict get $dmeths $key] ne ""} {
                            if {$mode eq "man"} {
                                puts [dict get $dmeths $key]
                            } else {
                                append mdhtml [dict get $dmeths $key]
                            }
                        }
                    }
                    
                }
                if {[regexp {<a\s+name='(methods|options|commands)'>} $line]} {
                    # clean up old keys, can't use dict unset for whatever reasons
                    foreach key [lsort [dict keys $dmeths]] {
                        dict set dmeths $key ""
                    }
                    set methods true
                }
                if {$methods && [regexp {[*_]{2}([-a-zA-Z0-9_]+?)[*_]{2}} $line -> meth]} {
                    set dkey $meth
                    dict set dmeths $dkey "$indent$line\n"
                    continue
                    
                } elseif {$methods && [info exists dkey]} {
                    set ometh [dict get $dmeths $dkey]
                    dict set dmeths $dkey "$ometh$indent$line\n"
                    continue
                }
                set line [regsub -all {!\[\]\((.+?)\)} $line "<image src=\"\\1\"></img>"]
                append mdhtml "$indent$line\n"
            }
        }
        if {$mode eq "html"} {
            set htm [Markdown::convert $mdhtml]
            set html ""
            # synopsis fix as in tcllib with blue background
            set synopsis false
            foreach line [split $htm "\n"] {
                if {[regexp {^<h2>} $line]} {
                    set synopsis false
                } 
                if {[regexp -nocase {^<h2>.*Synopsis} $line]} {
                    set synopsis true
                }
                if {$synopsis && [regexp {<pre>} $line]} {
                    set line [regsub {<pre>} $line "<pre class='synopsis'>"]
                } 
                set line [regsub {(<pre class='code)'(><code class=')(.+?)'>} $line "\\1 \\3'\\2\\3'>"]
                append html "$line\n"
            }
            set out [open $outfile w 0644]
            if {$extract} {
                puts $out $header
                puts $out $htmltitle
            } else {
                set header [subst -nobackslashes -nocommands $header]
                puts $out $header
            }
            if {[info exists document(title)]} {
                puts $out "<h1 class=\"title\">$document(title)</h1>"
            }
            if {[info exists document(author)]} {
                puts $out "<h2 class=\"author\">$document(author)</h2>"
            }
            if {[info exists document(date)]} {
                puts $out "<h2 class=\"date\">$document(date)</h2>"
            }
            puts $out $html
            puts $out "</body>\n</html>"
            close $out
            if {!$quiet} {
                puts "Success: file $outfile was written!"
            }
        } elseif {$mode eq "pandoc"} {
            set out [open $outfile w 0644]
            puts $out $YAML
            puts $out $mdhtml
            close $out
            
        } else {
            set out [open $outfile w 0644]
            puts $out $mdheader
            puts $out $mdhtml
            close $out
        }
    }
}
#' 
#' <a name="run" />
#' **mkdoc::run** *infile* 
#' 
#' > Source the code in infile and runs the examples in the documentation section
#'    written with Markdown documentation. Below follows an example section which can be
#'    run with `tclsh mkdoc.tcl mkdoc.tcl -run`
#' 
#' ## <a name="example">EXAMPLE</a>
#' 
#' ```
#' puts "Hello mkdoc package"
#' puts "I am in the example section"
#' ```
#' 
proc ::mkdoc::run {argv} {
    set filename [lindex $argv 0]
    if {[llength $argv] == 3} {
        set t [lindex $argv 2]
    } else {
        set t 1
    }
    source $filename
    set extext ""
    set example false
    set excode false
    if [catch {open $filename r} infh] {
        puts stderr "Cannot open $filename: $infh"
        exit
    } else {
        while {[gets $infh line] >= 0} {
            # Process line
            if {$extext eq "" && [regexp -nocase \
                             {^\s*#'\s+#{2,3}\s.+Example} $line]} {
                set example true
            } elseif {$extext ne "" && \
                      [regexp -nocase "^\\s*#'.*\\s# demo: $extext" $line]} {
                set excode true
            } elseif {$example && [regexp {^\s*#'\s+>?\s*```} $line]} {
                set example false
                set excode true
            } elseif {$excode && [regexp {^\s*#'\s+>?\s*```} $line]} {
                namespace eval :: $code
                break
                # eval code
            } elseif {$excode && [regexp {^\s*#'\s(.+)} $line -> c]} {
                append code "$c\n"
            }
        }
        close $infh
        if {$t > -1} {
            catch {
                update idletasks
                after [expr {$t*1000}]
                destroy .
            }
        }
    }
}
if {[info exists argv0] && $argv0 eq [info script]} {
    if {[lsearch $argv {--version}] > -1} {
        puts "[package provide mkdoc::mkdoc]"
        return
    } elseif {[lsearch $argv {--license}] > -1} {
        puts "MIT License - see manual page"
        return
    }
    if {[llength $argv] < 2 || [lsearch $argv {--help}] > -1} {
        puts "mkdoc - extract documentation in Markdown and convert it optionally into HTML"
        puts "        Author/Copyright: @ Detlef Groth, Caputh, Germany, 2019-2020"
        puts "        License: MIT"
        puts "\nUsage:  [info script] inputfile outputfile ?--html|--md|--pandoc --version --run 1 --css file.css?\n"
        puts "     inputfile: the inputfile with embedded Markdown text after #' comments"
        puts "     outputfile: should have either the extension html or md "
        puts "        for automatic selection of the correct output format."  
        puts "        Deduction of output format can be suppressed by given mode flags:"
        puts "     --html, --md or --pandoc"
        puts "        --html give HTML output even if outputfile extension is not html"
        puts "        --md   give Markdown output event if outputfile extension is not md"
        puts "        --pandoc command line argument will emmit as well the YAML header"
        puts "          header which is a Markdown extension."
        puts "     --css file.css: use the given stylesheet filename instead of the"
        puts "           inbuild default on"
        puts "     --help: shows this help page"        
        puts "     --version: returns the package version"
        puts "     --run: runs the example section in the input file finishs after the given time (default) 1"        
        puts "  Example: extract mkdoc's own embedded documentation as html:"
        puts "       tclsh mkdoc.tcl mkdoc.tcl mkdoc.html" 
        #        puts "        The -rox2md flag extracts roxygen2 R documentation from R script files"
        #        puts "        and converts them into markdown"
    } elseif {[llength $argv] >= 2 && [lsearch $argv {--run}] == 1} {
        mkdoc::run $argv 
    } elseif {[llength $argv] == 2} {
        mkdoc::mkdoc [lindex $argv 0] [lindex $argv 1]
    } elseif {[llength $argv] > 2} {
        mkdoc::mkdoc [lindex $argv 0] [lindex $argv 1] [lrange $argv 2 end]
    }
}

#'
#' ## <a name='format'>BASIC FORMATTING</a>
#' 
#' For a complete list of Markdown formatting commands consult the basic Markdown syntax at [https://daringfireball.net](https://daringfireball.net/projects/markdown/syntax). 
#' Here just the most basic essentials  to create documentation are described.
#' Please note, that formatting blocks in Markdown are separated by an empty line, and empty line in this documenting mode is a line prefixed with the `#'` and nothing thereafter. 
#'
#' **Title and Author**
#' 
#' Title and author can be set at the beginning of the documentation in a so called YAML header. 
#' This header will be as well used by the document converter [pandoc](https://pandoc.org)  to handle various options for later processing if you extract not HTML but Markdown code from your documentation.
#'
#' A YAML header starts and ends with three hyphens. Here is the YAML header of this document:
#' 
#' ```
#' #' ---
#' #' title: mkdoc - Markdown extractor and formatter
#' #' author: Dr. Detlef Groth, Schwielowsee, Germany
#' #' ---
#' ```
#' 
#' Those four lines produce the two lines on top of this document. You can extend the header if you would like to process your document after extracting the Markdown with other tools, for instance with Pandoc.
#' 
#' You can as well specify an other style sheet, than the default by adding
#' the following style information:
#'
#' ```
#' #' ---
#' #' title: mkdoc - Markdown extractor and formatter
#' #' author: Dr. Detlef Groth, Schwielowsee, Germany
#' #' output:
#' #'   html_document:
#' #'     css: tufte.css
#' #' ---
#' ```
#' 
#' Please note, that the indentation is required and it is two spaces.
#'
#' **Headers**
#'
#' Headers are prefixed with the hash symbol, single hash stands for level 1 heading, double hashes for level 2 heading, etc.
#' Please note, that the embedded style sheet centers level 1 and level 3 headers, there are intended to be used
#' for the page title (h1), author (h3) and date information (h3) on top of the page.
#' ```
#' #' ## <a name="sectionname">Section title</a>
#' #'
#' #' Some free text that follows after the required empty 
#' #' line above ...
#' ```
#'
#' This produces a level 2 header. Please note, if you have a section name `synopsis` the code fragments thereafer will be hilighted different than the other code fragments. You should only use level 2 and 3 headers for the documentation. Level 1 header are reserved for the title.
#' 
#' **Lists**
#'
#' Lists can be given either using hyphens or stars at the beginning of a line.
#'
#' ```
#' #' - item 1
#' #' - item 2
#' #' - item 3
#' ```
#' 
#' Here the output:
#'
#' - item 1
#' - item 2
#' - item 3
#' 
#' A special list on top of the help page could be the table of contents list. Here is an example:
#'
#' ```
#' #' ## Table of Contents
#' #'
#' #' - [Synopsis](#synopsis)
#' #' - [Description](#description)
#' #' - [Command](#command)
#' #' - [Example](#example)
#' #' - [Authors](#author)
#' ```
#'
#' This will produce in HTML mode a clickable hyperlink list. You should however create
#' the name targets using html code like so:
#'
#' ```
#' ## <a name='synopsis'>Synopsis</a> 
#' ```
#' 
#' **Hyperlinks**
#'
#' Hyperlinks are written with the following markup code:
#'
#' ```
#' [Link text](URL)
#' ```
#' 
#' Let's link to the Tcler's Wiki:
#' 
#' ```
#' [Tcler's Wiki](https://wiki.tcl-lang.org/)
#' ```
#' 
#' produces: [Tcler's Wiki](https://wiki.tcl-lang.org/)
#'
#' **Indentations**
#'
#' Indentations are achieved using the greater sign:
#' 
#' ```
#' #' Some text before
#' #'
#' #' > this will be indented
#' #'
#' #' This will be not indented again
#' ```
#' 
#' Here the output:
#'
#' Some text before
#' 
#' > this will be indented
#' 
#' This will be not indented again
#'
#' Also lists can be indented:
#' 
#' ```
#' > - item 1
#'   - item 2
#'   - item 3
#' ```
#'
#' produces:
#'
#' > - item 1
#'   - item 2
#'   - item 3
#'
#' **Fontfaces**
#' 
#' Italic font face can be requested by using single stars or underlines at the beginning 
#' and at the end of the text. Bold is achieved by dublicating those symbols:
#' Monospace font appears within backticks.
#' Here an example:
#' 
#' ```
#' I am _italic_ and I am __bold__! But I am programming code: `ls -l`
#' ```
#'
#' > I am _italic_ and I am __bold__! But I am programming code: `ls -l`
#' 
#' **Code blocks**
#'
#' Code blocks can be started using either three or more spaces after the #' sequence 
#' or by embracing the code block with triple backticks on top and on bottom. Here an example:
#' 
#' ```
#' #' ```
#' #' puts "Hello World!"
#' #' ```
#' ```
#'
#' Here the output:
#'
#' ```
#' puts "Hello World!"
#' ```
#'
#' **Images**
#'
#' If you insist on images in your documentation, images can be embedded in Markdown with a syntax close to links.
#' The links here however start with an exclamation mark:
#' 
#' ```
#' ![image caption](filename.png)
#' ```
#' 
#' The source code of mkdoc.tcl is a good example for usage of this source code 
#' annotation tool. Don't overuse the possibilities of Markdown, sometimes less is more. 
#' Write clear and concise, don't use fancy visual effects.
#' 
#' **Includes**
#' 
#' mkdoc in contrast to standard markdown as well support includes. Using the `#' #include "filename.md"` syntax 
#' it is possible to include other markdown files. This might be useful for instance to include the same 
#' header or a footer in a set of related files.
#'
#' ## <a name='install'>INSTALLATION</a>
#' 
#' The mkdoc::mkdoc package can be installed either as command line application or as a Tcl module. It requires the Markdown package from tcllib to be installed.
#' 
#' Installation as command line application can be done by copying the `mkdoc.tcl` as 
#' `mkdoc` to a directory which is in your executable path. You should make this file executable using `chmod`. There exists as well a standalone script which does not need already installed tcllib package.  You can download this script named: `mkdoc-version.app` from the [chiselapp release page](https://chiselapp.com/user/dgroth/repository/tclcode/wiki?name=releases).
#' 
#' Installation as Tcl module is achieved by copying the file `mkdoc.tcl` to a place 
#' which is your Tcl module path as `mkdoc/mkdoc-0.1.tm` for instance. See the [tm manual page](https://www.tcl.tk/man/tcl8.6/TclCmd/tm.htm)
#'
#' ## <a name='see'>SEE ALSO</a>
#' 
#' - [tcllib](https://core.tcl-lang.org/tcllib/doc/trunk/embedded/index.md) for the Markdown and the textutil packages
#' - [dgtools](https://chiselapp.com/user/dgroth/repository/tclcode) project for example help page
#' - [pandoc](https://pandoc.org) - a universal document converter
#' - [Ruff!](https://github.com/apnadkarni/ruff) Ruff! documentation generator for Tcl using Markdown syntax as well

#' 
#' ## <a name='changes'>CHANGES</a>
#'
#' - 2019-11-19 Relase 0.1
#' - 2019-11-22 Adding direct conversion from Markdown files to HTML files.
#' - 2019-11-27 Documentation fixes
#' - 2019-11-28 Kit version
#' - 2019-11-28 Release 0.2 to fossil
#' - 2019-12-06 Partial R-Roxygen/Markdown support
#' - 2020-01-05 Documentation fixes and version information
#' - 2020-02-02 Adding include syntax
#' - 2020-02-26 Adding stylesheet option --css 
#' - 2020-02-26 Adding files pandoc.css and dgw.css
#' - 2020-02-26 Making standalone file using pkgDeps and mk_tm
#' - 2020-02-26 Release 0.3 to fossil
#' - 2020-02-27 support for \_\_DATE\_\_, \_\_PKGNAME\_\_, \_\_PKGVERSION\_\_ macros  in Tcl code based on package provide line
#' - 2020-09-01 Roxygen2 plugin
#' - 2020-11-09 argument --run supprt
#' - 2020-11-10 Release 0.4
#' - 2020-11-11 command line option  --run with seconds
#' - 2020-12-30 Release 0.5 (rox2md @section support with preformatted, emph and strong/bold)
#' - 2022-01-XX Release 0.6 parsing yaml header, workaround for images, seems not to work with library Markdown
#' - 2023-04-17 0.6.1 - fix for Unicode support within code blocks
#'
#' ## <a name='todo'>TODO</a>
#'
#' - extract Roxygen2 documentation codes from R files (done)
#' - standalone files using mk_tm module maker (done, just using cat ;)
#' - support for \_\_PKGVERSION\_\_ and \_\_PKGNAME\_\_ replacements at least in Tcl files and via command line for other file types (done)
#'
#' ## <a name='authors'>AUTHOR(s)</a>
#'
#' The **mkdoc::mkdoc** package was written by Dr. Detlef Groth, Schwielowsee, Germany.
#'
#' ## <a name='license'>LICENSE AND COPYRIGHT</a>
#'
#' Markdown extractor and converter mkdoc::mkdoc, version __PKGVERSION__
#'
#' Copyright (c) 2019-23  Dr. Detlef Groth, E-mail: <detlef(at)dgroth(dot)de>
#' 
#' This library is free software; you can use, modify, and redistribute it
#' for any purpose, provided that existing copyright notices are retained
#' in all copies and that this notice is included verbatim in any
#' distributions.
#' 
#' This software is distributed WITHOUT ANY WARRANTY; without even the
#' implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#'


