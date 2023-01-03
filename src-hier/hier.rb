require 'yaml'
@keys = {}
@paths = {}

def do_rec(ak, rec)
        @keys[ak] = rec
        nav = rec.fetch("nav", {}).fetch("path", "undefined")
        @paths[nav] = @paths.fetch(nav, []).append(ak)
end

YAML.load_file("../src-admintool/config/reports.yml").each do |k, rec|
        do_rec("rpt_#{k}", rec)
end

YAML.load_file("../src-colladmin/config/actions.yml").each do |k, rec|
        do_rec("act_#{k}", rec)
end

@paths.keys.sort.each do |n|
        puts "- **#{n}**"
        @paths[n].each do |k|
                puts "  - #{k}: #{@keys[k].fetch('link-title','')}"
        end
end