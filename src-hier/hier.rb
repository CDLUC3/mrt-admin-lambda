require 'yaml'
@keys = {}
@paths = {}
@written = {}

@pages = [
        "/home/objects/query/page: Search by ARK - ark.html",
        "/home/objects/query/page: Search by DOI - doi.html",
        "/home/objects/query/page: Search by LocalId- localid.html",
        "/home/sub-applications/collection-admin/page: Admin Object Properties - artifactProperties.html",
        "/home/sub-applications/collection-admin/page: Submit Admin Objects - collAdminObjs.html",
        "/home/sub-applications/collection-admin/page: Create Admin Object - collProfile.html",
        "/home/sub-applications/storage-node-configuration/page: Manage Storage Node for Collection - storeCollNode.html",
        "/home/sub-applications/storage-node-configuration/page: Manage Storage Node for Collections - storeCollNodes.html",
        "/home/sub-applications/storage-scan/page: Storage Node Scan - storeNodes.html",
        "/home/sub-applications/storage-scan/page: Storage Node Scan History - storeScans.html",
        "/home/sub-applications/storage-scan/page: Storage Node Scan Result Review - storeNodeReview.html",
        "/home/sub-applications/object-management/page: Object List - Storage Management - storeObjects.html",
        "/home/sub-applications/object-management/page: Object Storage Management - storeObjectNodes.html",
        "/home/sub-applications/audit-batches/page: Manage Audit Queues - storeQueues.html",
]

def add_path(nav, ak)
        narr = nav.split("/")
        for i in 1..narr.length-1 
                np = narr[0..i].join("/")
                @paths[np] = @paths.fetch(np, [])
        end
        @paths[nav] = @paths.fetch(nav, []).append(ak) unless ak.empty?
end

def do_rec(ak, rec)
        @keys[ak] = rec
        nav = rec.fetch("nav", {}).fetch("path", "undefined")
        add_path(nav, ak)
end

YAML.load_file("../src-admintool/config/reports.yml").each do |k, rec|
        do_rec("rpt_#{k}", rec)
end

YAML.load_file("../src-colladmin/config/actions.yml").each do |k, rec|
        do_rec("act_#{k}", rec)
end

@pages.each do |p|
        add_path(p, '')
end

@paths.keys.sort.each do |n|
        h = ""
        narr = n.split("/")
        for i in 1..narr.length-1
                h += "  "
        end
        puts "#{h}- **#{narr[-1]}**"
        @paths[n].each do |k|
                puts "#{h}  - #{k}: #{@keys.fetch(k, {}).fetch('link-title','')}"
        end
end