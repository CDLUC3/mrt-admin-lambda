require 'yaml'
@keys = {}
@paths = {}
@written = {}

def do_rec(ak, rec)
        @keys[ak] = rec
        nav = rec.fetch("nav", {}).fetch("path", "undefined")
        narr = nav.split("/")
        for i in 1..narr.length-1 
                np = narr[0..i].join("/")
                @paths[np] = @paths.fetch(np, [])
        end
        @paths[nav] = @paths.fetch(nav, []).append(ak)
end

YAML.load_file("../src-admintool/config/reports.yml").each do |k, rec|
        do_rec("rpt_#{k}", rec)
end

YAML.load_file("../src-colladmin/config/actions.yml").each do |k, rec|
        do_rec("act_#{k}", rec)
end

@paths.keys.sort.each do |n|
        h = ""
        narr = n.split("/")
        for i in 1..narr.length-1
                h += "  "
        end
        puts "#{h}- **#{narr[-1]}**"
        @paths[n].each do |k|
                puts "#{h}  - #{k}: #{@keys[k].fetch('link-title','')}"
        end
end