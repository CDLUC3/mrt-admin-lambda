var iterativeParams = [];
var urlbase = "";
var pageparams = {};

function api_alert(msg) {
  $("#alertmsg").text(msg).dialog({
    show: { effect: "blind", duration: 800 }
  });
}


$(document).ready(function(){
  $("#bytes").on("change", function(){updateBytesUnits();});
  $("p.buttons")
    .hide();
  $("#exportTable").on('click', function(){
    exportTable($('table tbody tr:visible'));
  });
  pageparams = getParams();
  var path = ('path' in pageparams) ? pageparams['path'] : '';
  urlbase = path == '' ? '' : lambda_base + "/" + path;
  var url = path == '' ? '' : urlbase; // + document.location.search;

  consistencyStatus();

  if (url != '') {
    showUrl(url);
    $("#menu").hide();
  } else {
    $("#menu").show();
  }
});

function consistencyStatus() {
  if ($("#consistency").is("*")) {
    $.ajax({
      dataType: "json",
      method: 'GET',
      url: lambda_base,
      data: {path: 'report'},
      success: function(data) {
        var m = data.report_path.match(/(SKIP|PASS|INFO|WARN|FAIL)$/);
        $("#consistency").text(m[1]).addClass(m[1]);
      }
    });  
  }
}

function updateBytesUnits() {
  var factor = $("#bytes").val();
  $("td.bytes").each(function(){
    var v = $(this).attr('data');
    if (v) {
      var n  = Number(v) / factor;
      if (n == 0) {
        return;
      }
      var dig = factor == 1 || factor == 1000000 ? 0 : 2;
      v = n.toLocaleString(undefined, {minimumFractionDigits: dig, maximumFractionDigits:dig});
      if (v == '0' || v == '0.00') {
        v += "*";
      } else {
        v += " ";
      }
      if (factor == 1000000) {
        v += "M";
      } else if (factor == 1000000000) {
        v += "G";
      } else if (factor == 1000000000000) {
        v += "T";
      }
      $(this).text(v);
    }
  });
}

function iterateParams(parr) {
  params = pageparams;
  delete params['iterate'];
  params['itparam1'] = parr.length > 0 ? parr[0] : '';
  params['itparam2'] = parr.length > 1 ? parr[1] : '';
  params['itparam3'] = parr.length > 2 ? parr[2] : '';
  return params;
}

function getParams(){
  var queries = {};
  if (document.location.search == "") {
    return queries;
  }
  $.each(document.location.search.substr(1).split('&'),function(c,q){
    var i = q.split('=');
    queries[i[0].toString()] = i[1].toString();
  });
  return queries;
}

function showData(file) {
  var url = "data/" + file + ".json";
  showUrl(url);
}

function showUrl(url) {
  $("#in-progress").dialog({
    title: "Please wait",
    modal: true,
    width: 350,
    position: {
      my: "center",
      at: "center",
      of: window,
      collision: "none"
    }
  });

  if (pageparams['method'] == "post" ) {
    method = "POST";
    path = ('path' in pageparams) ? pageparams['path'] : 'path-na';
    key = ('key' in pageparams) ? pageparams['key'] : 'key-na';
    value = (key in localStorage) ? localStorage[key] : 'na';
    pageparams[key] = value;
    pageparams['path'] = path;
  } else {
    method = "GET";
  }
  $.ajax({
    dataType: "json",
    method: method,
    url: url,
    data: pageparams,
    success: function(data) {
      if ("bytes_unit" in data) {
        $("#bytes").val(data["bytes_unit"])
      }
      processResult(data);
      if (method == "POST") {
        $("#exportJson").hide();
      }
    },
    error: function( xhr, status ) {
      api_alert("An error has occurred.  Possibly a timeout.\n"+xhr.responseText)
      $("#in-progress").dialog("close");
    }
  });

}

function processResult(data) {
  if (data.redirect_location) {
    document.location = data.redirect_location;
    return;
  }
  $("h1,title").text(data.title);
  $(".report_path").text(data.report_path);

  if (data.format == 'report'){
    createTable(
      data.headers,
      data.types,
      data.data,
      data.filter_col,
      data.group_col,
      data.show_grand_total,
      data.show_iterative_total,
      data.merritt_path,
      data.alternative_queries,
      data.iterate,
      data.description
    )

    if (data.chart) {
      $("#chartdiv").show();
      const myChart = new Chart(
        document.getElementById('myChart'),
        data.chart
      );
    }

    if (data.breadcrumb) {
      if (data.breadcrumb != '') {
        $(".breadpath").hide();
        $('.breadpath_home').show();
        $("." + data.breadcrumb).show();
        $(".bp_title").text(data.title).show();
      }
    }

    setRequeueAll();
    setDeleteAll();
  } else {
    document.body.innerHTML = JSON.stringify(data);
  }
}

function setRequeueAll() {
  $("li.requeue-all a").on("click", function(){
    doRequeue();
  });

  testRequeue();  
}

function setDeleteAll() {
  $("li.deleteq-all a").on("click", function(){
    doDeleteQ();
  });

  testDeleteQ();  
}

function doRequeue() {
  var link = $("a.ajax:contains('Requeue'):not(.disabled):first");
  if (link.is("*")) {
    link[0].click();
    link.addClass("disabled");
    setTimeout(function(){doRequeue()}, 3000);
  }

}

function doDeleteQ() {
  var link = $("a.ajax:contains('Delete'):not(.disabled):first");
  if (link.is("*")) {
    link[0].click();
    link.addClass("disabled");
    setTimeout(function(){doDeleteQ()}, 3000);
  }

}

function testRequeue() {
  $("li.requeue-all a").addClass("disabled");
  if ($("a.ajax:contains('Requeue'):not(.disabled)").is("*")) {
    $("li.requeue-all a").removeClass("disabled");
  }
}

function testDeleteQ() {
  $("li.deleteq-all a").addClass("disabled");
  if ($("a.ajax:contains('Delete'):not(.disabled)").is("*")) {
    $("li.deleteq-all a").removeClass("disabled");
  }
}

function showCounts() {
  if ($("#data-table caption").length == 0) {
    $("<caption/>").insertBefore($("#data-table thead"));
  } 
  var vcount = $("#data-table tbody tr:visible").length;
  var rcount = $("#data-table tbody tr").length;
  $("#data-table caption").text(vcount + " of " + rcount + " Rows");  
}

function postLoad() {
  showCounts();
  if ($("#bytes").val() != "1") {
    updateBytesUnits();
  }
  $("tr:has('td.ajaxdoi'):first").each(function(){
    var tr = $(this);
    var job =  tr.find("td.qjob").text();
    var url = urlbase + "?path=job&batch=JOB_ONLY&job=" + job;
    $.ajax({
      dataType: "json",
      url: url,
      success: function(data) {
        var mdata = data.data;
        var ark = "";
        var doi = "";
        if (mdata) {
          for(var i=0; i< mdata.length; i++) {
            var r = mdata[i];
            if (r.length == 2) {
              if (r[0] == "fil:where-primary") {
                ark = r[1];
              }
              if (r[0] == "fil:where-local") {
                doi = r[1];
              }
            }
          }
        }
        tr.find("td.ajaxdoi").text(doi).removeClass("ajaxdoi");
        tr.find("td.ajaxark").text(ark).removeClass("ajaxark");
        postLoad();
      },
      error: function( xhr, status ) {
        tr.find("td.ajaxdoi").text("").removeClass("ajaxdoi");
        tr.find("td.ajaxark").text("").removeClass("ajaxark");
        postLoad();
      }
    });
  });

}

function query_iterate(show_iterative_total, types, data){
  for(var r=0; r<data.length; r++) {
    alldata.push(data[r]);
  }
  if (iterativeParams.length == 0) {
    sorttable.makeSortable($("#data-table")[0]);
    if (show_iterative_total) {
      totr = createTotalRow("grandtotal", null, null, types, "")
        .appendTo("#data-table tbody");
      var gtotdata = createTotalData(types);
      for(var r=0; r<alldata.length; r++) {
        updateTotalData(gtotdata, types, alldata[r]);
      }
      updateTotalRow(totr, types, gtotdata);
    }
    $("#in-progress").dialog("close");
    $("#iprogress").text("");
    postLoad();
  } else {
    var itparam = iterativeParams.shift();
    $("#iprogress").text("Queries Remaining: "+iterativeParams.length);
    $.ajax({
      dataType: "json",
      url: urlbase,
      data: iterateParams(itparam),
      success: function(data) {
        appendTable(
          data.headers,
          data.types,
          data.data,
          data.filter_col,
          data.group_col,
          data.show_grand_total,
          data.show_iterative_total,
          data.merritt_path
        )
      },
      error: function( xhr, status ) {
        api_alert("An error has occurred.  Possibly a timeout.\n"+xhr.responseText)
        $("#in-progress").dialog("close");
      }
    });
  }
}

var alldata = [];
function createTable(headers, types, data, filter_col, group_col, show_grand_total, show_iterative_total, merritt_path, alternative_queries, iterate, description) {
  $("p.buttons")
    .show();
  $('#alternative ul').empty().hide();
  $.each(alternative_queries, function(i, q){
    var url = '';
    if (q['url'] == '') {
      url = '#';
    } else if (q['url'].substr(0,1) == '#'){
      url = q['url'];
    } else if (q['url'].substr(0,4) == 'http'){
      url = q['url'];
    } else if (q['url'].substr(0,1) == '/') {
      url = document.location.pathname.replace(/\/[^\/]*$/, '') + q['url'];
    } else {
      url = document.location.pathname + "?" + q['url'];
    }
    var c = ('class' in q) ? q['class'] : '';
    $('#alternative ul').show().append(
      $("<li/>").append(
        $("<a/>").text(q['label']).attr('href', url)
      ).addClass(c)
    );
  });
  $("#exportJson").attr("href", urlbase + document.location.search + "&format=json");
  $("#data-table")
    .empty()
    .append($("<thead/>"))
    .append($("<tbody/>"));
  $("#report-description").hide();
  if (description) {
    if (description != '') {
      $("#report-description").append($(markdown(description))).show();
    } 
  }
  if (iterate) {
    $("#exportJson").hide();
    iterativeParams = data;
    query_iterate(show_iterative_total, types, data);
  } else {
    $("#exportJson").show();
    appendTable(headers, types, data, filter_col, group_col, show_grand_total, show_iterative_total, merritt_path);
  }
}

function createTotalRow(classname, group_col, filter_col, types, key) {
  var totr = $("<tr/>").addClass(classname);
  for(var c=0; c<types.length; c++) {
    if (types[c] == 'na') {
      continue;
    }
    data = "";
    if (c == filter_col) {
      data = (classname == "total") ? "-- Total --" : "-- Grand Total --";
    } else if (c == group_col) {
      data = key;
    } else if (types[c] == "money" || types[c] == "dataint" || types[c] == "bytes") {
      data = "";
    }
    totr.append(createCell(data, types[c], false, "").addClass("c"+c));
  }
  return totr;
}

function updateTotalRow(totr, types, totdata) {
  for(var c=0; c<types.length; c++) {
    if (types[c] == 'na') {
      continue;
    }
    if (totdata[c] == null) {
      continue;
    }
    var n = Number(totdata[c]);
    var data = n.toLocaleString(undefined, {minimumFractionDigits: 0, maximumFractionDigits:0});
    if (types[c] == 'money') {
      data = n.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits:2});
    } 
    totr.find(".c" + c).text(data);
    totr.find(".c" + c).attr('title', data);
    totr.find(".c" + c).attr('data', n);
  }
}

function createTotalData(types) {
  var data = [];
  for(var c=0; c<types.length; c++) {
    if (types[c] == "money" || types[c] == "dataint" || types[c] == "bytes") {
      data.push(0);
    } else {
      data.push(null);
    }
  }
  return data;
}

function updateTotalData(totdata, types, row) {
  for(var c=0; c<types.length; c++) {
    if (totdata[c] == null) {
      continue;
    }
    if ($.isNumeric(row[c])) {
      totdata[c] += Number(row[c]);
    }
  }
  return totdata;
}

function appendTable(headers, types, data, filter_col, group_col, show_grand_total, show_iterative_total, merritt_path) {
  if ($("#data-table tr.header").length == 0) {
    var tr = $("<tr/>").appendTo("#data-table thead");
    tr.addClass("header");
    for(var c=0; c<headers.length; c++) {
      if (types[c] != 'na') {
        var cell = createCell(headers[c], types[c], true, merritt_path);
        tr.append(cell);
      }
    }
  }

  var totdata = createTotalData(types);
  var gtotdata = createTotalData(types);
  var totr = null;
  var last = null;
  for(var r=0; r<data.length; r++) {
    var curval = (group_col != null) ? data[r][group_col] : null;
    if (curval != last) {
      if (totr != null) {
        updateTotalRow(totr, types, totdata);
      }
      totdata = createTotalData(types);
      last = curval;
      totr = createTotalRow("total", group_col, filter_col, types, last)
        .appendTo("#data-table tbody");
    }
    updateTotalData(totdata, types, data[r]);
    updateTotalData(gtotdata, types, data[r]);
    tr = $("<tr/>").appendTo("#data-table tbody");

    rclass = "row";
    if (filter_col != null) {
      if (data[r][filter_col] == '-- Total --') {
        rclass = "total"
      } else if (data[r][filter_col] == '-- Grand Total --') {
        rclass = "grandtotal"
      } else if (data[r][filter_col] == '-- Special Total --') {
        rclass = "specialtotal"
      }
    }
    tr.addClass(rclass);

    for(var c=0; c<data[r].length; c++) {
      if (types[c] != 'na') {
        var cell = createCell(data[r][c], types[c], false, merritt_path);
        tr.append(cell);
        if (types[c] == 'status') {
          if (cell.hasClass('status-FAIL')) {
            tr.addClass('status-FAIL');
          } else if (cell.hasClass('status-INFO')) {
            tr.addClass('status-INFO');
          } else if (cell.hasClass('status-WARN')) {
            tr.addClass('status-WARN');
          } else if (cell.hasClass('status-PASS')) {
            tr.addClass('status-PASS');
          }
        }
      }
    }
    if (totr != null) {
      updateTotalRow(totr, types, totdata);
    }
    if (tr.find("td.hasdata,th.hasdata").length == 0) {
      tr.addClass("nodata");
    }
    if (tr.find("td.flag,th.flag").length == 0) {
      tr.addClass("noflag");
    }
  }

  if (show_grand_total) {
    totr = createTotalRow("grandtotal", group_col, filter_col, types, "")
      .appendTo("#data-table tbody");
    updateTotalRow(totr, types, gtotdata);
  }

  $("#in-progress").dialog({
    position: {
      my: "center",
      at: "center",
      of: window,
      collision: "none"
    }
  });
  query_iterate(show_iterative_total, types, data);
}

function createCell(v, type, isHeader, merritt_path) {
  var cell = isHeader ? $("<th/>") : $("<td/>");
  cell.addClass("cell").addClass(type);
  format(cell, v, isHeader ? '' : type, merritt_path);
  return cell;
}

function makeLink(parent, v, href) {
  return $("<a/>")
    .text(v)
    .attr("href", href)
    .appendTo(parent);
}

function makeLiLink(parent, v, href) {
  return $("<li/>")
    .append(
      $("<a/>")
        .text(v)
        .attr("href", href)
    )
    .appendTo(parent);
}

function makeLiLinkTarget(parent, v, href, target) {
  return $("<li/>")
    .append(
      $("<a/>")
        .text(v)
        .attr("href", href)
        .attr("target", target)
    )
    .appendTo(parent);
}

function makeUl(parent) {
  return $("<ul/>")
    .appendTo(parent);
}


function makeLi(parent, v) {
  return $("<li/>")
    .text(v)
    .appendTo(parent);
}

function format(cell, v, type, merritt_path) {
  if (v == null) {
  } else if (type == 'foo') {
    $("<a href='?json=foo'/>").text(v).appendTo(cell);
  } else if (type == 'money'){
    var vf = Number(v).toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits:2});
    cell.text(vf);
    cell.addClass("hasdata");
    cell.attr('data', Number(v));
  } else if (type == 'dataint'){
    var vf = Number(v).toLocaleString(undefined, {minimumFractionDigits: 0, maximumFractionDigits:0});
    cell.text(vf);
    cell.addClass("hasdata");
    cell.attr('data', Number(v));
  } else if (type == 'bytes'){
    var vf = Number(v).toLocaleString(undefined, {minimumFractionDigits: 0, maximumFractionDigits:0});
    cell.text(vf);
    cell.attr('title', vf);
    cell.addClass("hasdata");
    cell.attr('data', Number(v));
  } else if (type == 'data'){
    var vf = Number(v).toLocaleString(undefined, {minimumFractionDigits: 0, maximumFractionDigits:0});
    cell.text(vf);
    cell.addClass("hasdata");
    cell.attr('data', Number(v));
  } else if (type == 'datetime'){
    cell.text(v.replace(/ [-\+]\d+$/,''));
  } else if (type == 'node' && Number(v) > 0){
    makeLink(cell, v, admintool_home + "?path=collections_by_node&node="+v);
  } else if (type == 'own' && Number(v) > 0){
    makeLink(cell, v, admintool_home + "?path=collections_by_owner&own="+v);
  } else if (type == 'mime' && !v.startsWith('--')){
    makeLink(cell, v, admintool_home + "?path=collections_by_mime_type&mime="+v);
  } else if (type == 'gmime' && v != '' && !v.startsWith('ZZ')){
    makeLink(cell, v, admintool_home + "?path=collections_by_mime_group&mime="+v);
  } else if (type == 'coll' && Number(v) > 0){
    makeLink(cell, v, admintool_home + "?path=collection_details&coll="+v);
  } else if (type == 'colllist' && v != '' && v != '0'){
    v = "" + v;
    var arr = v.split(",");
    if (arr.length == 1) {
      makeLink(cell, v, admintool_home + "?path=collection_info&coll="+v.replace(/_content$/, ''));
    } else {
      var ul = makeUl(cell);
      $.each(arr, function(i,txt){
        makeLiLink(ul, txt, admintool_home + "?path=collection_info&coll="+txt);
      });  
    }
  } else if (type == 'coll-date' && Number(v) > 0){
    makeLink(cell, v, admintool_home + "?path=objects_recent_coll&coll="+v);
  } else if (type == 'ogroup' && !v.startsWith('ZZ')){
    makeLink(cell, v, admintool_home + "?path=collection_group_details&coll="+v);
  } else if (type == 'batch') {
    makeLink(cell, v, admintool_home + "?path=objects_by_batch&batch="+v);
  } else if (type == 'batchnote') {
    var arr = v.split(";")
    if (arr.length == 2) {
      makeLink(cell, arr[1], admintool_home + "?path=objects_by_batch&batch="+arr[0]);
    } else {
      cell.text(v)
    }
  } else if (type == 'jobnote') {
    var arr = v.split(";")
    if (arr.length == 2) {
      batj = arr[0].split(/\//);
      if (batj.length == 2) {
        makeLink(cell, arr[1], admintool_home + "?path=objects_by_job&batch="+batj[0]+"&job="+batj[1]);
      } else {
        cell.text(v)
      }
    } else {
      cell.text(v)
    }
  } else if (type == 'job') {
    //todo... pass batch as well, job is not indexed
    makeLink(cell, v, admintool_home + "?path=objects_by_job&job="+v+"&batch=x");
  } else if (type == 'container') {
    makeLink(cell, v, admintool_home + "?path=objects_by_container_name&container="+v);
  } else if (type == 'qbatch') {
    makeLink(cell, v, colladmin_home + "?path=batch&batch="+v);
  } else if (type == 'ldapuid') {
    makeLink(cell, v, colladmin_home + "?path=ldap/user&uid="+v.replace(/^.*\(/,'').replace(/\)/,''));
  } else if (type == 'ldapcoll') {
    makeLink(cell, v, colladmin_home + "?path=ldap/coll&coll="+v.replace(/^.*\(/,'').replace(/\)/,''));
  } else if (type == 'ldapark') {
    makeLink(cell, v, colladmin_home + "?path=ldap/collark&ark="+v);
  } else if (type == 'qbatchnote') {
    var arr = v.split(";")
    if (arr.length == 2) {
      makeLink(cell, arr[1], colladmin_home + "?path=batch&batch="+arr[0]);
    } else {
      cell.text(v)
    }
  } else if (type == 'qjob') {
    var arr = v.split("/");
    var b = arr[0];
    var j = arr.length > 1 ? arr[1] : "";
    makeLink(cell, j, colladmin_home + "?path=manifest&batch="+b+"&job="+j);
  } else if (type == 'snodes') {
    makeLink(cell, v, colladmin_root + "/web/storeCollNode.html?coll="+v);
  } else if (type == 'mnemonic'){
    makeLink(cell, v, merritt_path + "/m/" + v);
  } else if (type == 'ark'){
    makeLink(cell, v, merritt_path + "/m/" + encodeURIComponent(v));
    cell.addClass("hasdata");
  } else if (type == 'arkdev'){
    makeLink(cell, v, "http://uc3-mrtdocker01x2-dev.cdlib.org:8086/m/" + encodeURIComponent(v));
    cell.addClass("hasdata");
  } else if (type == 'objlist'){
    makeLink(cell, v, "?path=filelist&id=" + v);
  } else if (type == 'alert'){
    if (v.match(/!$/)) {
      cell.addClass("flag");
      v = v.replace(/!$/, '');
    }
    cell.text(v);
  } else if (type == 'profile'){
    makeLink(cell, v, colladmin_home + "?path=profiles&profile=" + encodeURIComponent(v));
  } else if (type == 'list' && v != ''){
    var arr = v.split(",");
    if (arr.length == 1) {
      cell.text(v);
    } else {
      var ul = makeUl(cell);
      $.each(arr, function(i,txt){
        makeLi(ul, txt);
      });  
    }
    cell.addClass("hasdata");
  } else if (type == 'vallist' && (""+v).match(/^list:/)){
    var ul = makeUl(cell);
    $.each(v.replace(/^list:/,'').split(","), function(i,txt){
      makeLi(ul, txt);
    });
    cell.addClass("hasdata");
  } else if (type == 'list-doc' && v != ''){
    var ul = makeUl(cell);
    $.each(v.split(","), function(i,txt){
      makeLiLink(ul, txt.replace(/https:.*github\.com./, ''), txt);
    });
  } else if (type == 'ldapuidlist' && v != ''){
    var ul = makeUl(cell);
    $.each(v.split(","), function(i,txt){
      makeLiLink(ul, txt, colladmin_home + "?path=ldap/user&uid=" + txt.replace(/^.*\(/,'').replace(/\)/,''));
    });
    cell.addClass("hasdata");
  } else if (type == 'status'){
    cell.addClass("status-"+v);
    cell.text(v);
  } else if (type == 'report'){
    makeLink(cell, v, admintool_home + "?path=report&report=" + encodeURIComponent(v));
  } else if (type == 'aggrole') {
    makeLink(cell, v, admintool_home + "?path=admin_obj&aggrole="+v);
  } else if (type == 'cognito') {
    var arr = v.split(";");
    var yn = arr.length > 0 ? arr[0] : "";
    var u = arr.length > 1 ? arr[1] : "";
    var g = arr.length > 2 ? arr[2] : "";
    cell.text(yn + "; ");
    if (u != "" && g != "") {
      var param = "&user=" + encodeURIComponent(u) + "&group=" + encodeURIComponent(g);
      if (yn == "Y") {
        makeLink(cell, 'Remove', colladmin_home + "?path=cognito-remove-user-from-group" + param);
      } else {
        makeLink(cell, 'Add', colladmin_home + "?path=cognito-add-user-to-group" + param);
      }
    }
  } else if (type == 'astatus') {
    makeLink(cell, v, admintool_home + "?path=obj_audit_status&status="+v);
  } else if (type == 'endpoint'  && v != '') {
    var ul = makeUl(cell);
    $.each(v.split(";;"), function(i,txt){
      var arr = txt.split(";");
      var atext = arr.length > 0 ? arr[0] : "";
      var name = arr.length > 1 ? arr[1] : "";
      var title = arr.length > 2 ? arr[2] : "";
      var href = colladmin_root + "?path=instances&name="+name+"&label="+atext;
      var li;
      if (atext.match(/^\*/)) {
        li = makeLi(ul, atext.replace(/^\*/, ""));
        li.attr("title", "Use curl for this request" + title);
      } else if (atext.match(/^\+/)) {
        li = makeLiLinkTarget(ul, atext, title, "_blank");
        li.attr("title", "this link will open directly in the browser, it is not accessible to our lambda");
      } else if (atext.match(/^-/)) {
        li = makeLi(ul, atext);
        li.attr("title", "this link requires authentication to access");
      } else {
        li = makeLiLinkTarget(ul, atext, href, "_blank");
        li.attr("title", title);
      }
      li.append(" ");
      makeLink(li, "📋", "javascript:window.prompt('Copy to clipboard: Ctrl+C, Enter', '" +title+"')"); 
    });
  } else if (type == 'qdelete'  && v != '') {
    p = colladmin_root + "/lambda?path=queue-delete&queue-path="+v;
    makeLink(cell, 'Delete', "javascript:ajax_invoke('"+encodeURIComponent(p)+"')").addClass("ajax");
  } else if (type == 'qdelete-mrtzk'  && v != '') {
    p = colladmin_root + "/lambda?path=queue-delete-mrtzk&queue-path="+v;
    makeLink(cell, 'Delete', "javascript:ajax_invoke('"+encodeURIComponent(p)+"')").addClass("ajax");
  } else if (type == 'qdelete-batch-mrtzk'  && v != '') {
    p = colladmin_root + "/lambda?path=queue-delete-batch-mrtzk&queue-path="+v;
    makeLink(cell, 'Batch Delete', "javascript:ajax_invoke('"+encodeURIComponent(p)+"')").addClass("ajax");
  } else if (type == 'update-batch-mrtzk'  && v != '') {
    p = colladmin_root + "/lambda?path=queue-update-batch-mrtzk&queue-path="+v;
    makeLink(cell, 'Update Reporting', "javascript:ajax_invoke('"+encodeURIComponent(p)+"')").addClass("ajax");
  } else if (type == 'requeue'  && v != '') {
    p = colladmin_root + "/lambda?path=requeue&queue-path="+v;
    makeLink(cell, 'Requeue', "javascript:ajax_invoke('"+encodeURIComponent(p)+"');testRequeue()").addClass("ajax");
  } else if (type == 'requeue-mrtzk'  && v != '') {
    p = colladmin_root + "/lambda?path=requeue-mrtzk&queue-path="+v;
    makeLink(cell, 'Requeue', "javascript:ajax_invoke('"+encodeURIComponent(p)+"');testRequeue()").addClass("ajax");
  } else if (type == 'hold'  && v != '') {
    p = colladmin_root + "/lambda?path=hold-queue-item&queue-path="+v;
    makeLink(cell, 'Hold', "javascript:ajax_invoke('"+encodeURIComponent(p)+"')").addClass("ajax");
  } else if (type == 'hold-mrtzk'  && v != '') {
    p = colladmin_root + "/lambda?path=hold-queue-item-mrtzk&queue-path="+v;
    makeLink(cell, 'Hold', "javascript:ajax_invoke('"+encodeURIComponent(p)+"')").addClass("ajax");
  } else if (type == 'release'  && v != '') {
    p = colladmin_root + "/lambda?path=release-queue-item&queue-path="+v;
    makeLink(cell, 'Release', "javascript:ajax_invoke('"+encodeURIComponent(p)+"')").addClass("ajax");
  } else if (type == 'release-mrtzk'  && v != '') {
    p = colladmin_root + "/lambda?path=release-queue-item-mrtzk&queue-path="+v;
    makeLink(cell, 'Release', "javascript:ajax_invoke('"+encodeURIComponent(p)+"')").addClass("ajax");
  } else if (type == 'collqitems-mrtzk'  && v != '') {
    p = colladmin_root + "/lambda?path=release-coll-queue-items&coll="+v;
    makeLink(cell, 'Release Items', "javascript:ajax_invoke('"+encodeURIComponent(p)+"')").addClass("ajax");
  } else if (type == 'orphan'  && v != '') {
    p = colladmin_root + "/lambda?path=orphan-delete&queue-path="+v;
    makeLink(cell, 'Delete', "javascript:ajax_invoke('"+encodeURIComponent(p)+"')").addClass("ajax");
  } else if (type == 'colllock') {
    var arr = v.split(",");
    if (arr.length == 2) {
      p = colladmin_root + "/lambda?path=" + arr[0] + "-coll&coll=" + arr[1];
      makeLink(cell, arr[0], "javascript:ajax_invoke('"+encodeURIComponent(p)+"')").addClass("ajax");  
    }
  } else if (type == 'colllockzk') {
    var arr = v.split(",");
    if (arr.length == 2) {
      p = colladmin_root + "/lambda?path=" + arr[0] + "-collzk&coll=" + arr[1];
      makeLink(cell, arr[0], "javascript:ajax_invoke('"+encodeURIComponent(p)+"')").addClass("ajax");  
    }
  } else if (type == 'collnode'  && v != '') {
    makeLink(cell, 'Manage Coll Nodes', colladmin_root + "/web/storeCollNode.html?coll="+v);
  } else if (type == 'fprofile') {
    makeLink(cell, v, colladmin_home + "?path=queues&profile="+v);
  } else if (type == 'fbatch') {
    makeLink(cell, v, colladmin_home + "?path=queues&batch="+v);
  } else if (type == 'fstatus') {
    makeLink(cell, v, colladmin_home + "?path=queues&qstatus="+v);
  } else if (type == 'fprofilestatus') {
    arr = v.split(";");
    if (arr.length == 3) {
      makeLink(cell, arr[2], colladmin_home + "?path=queues&profile="+arr[0]+"&qstatus="+arr[1]);
    }
  } else if (type == 'fbatchstatus') {
    arr = v.split(";");
    if (arr.length == 3) {
      makeLink(cell, arr[2], colladmin_home + "?path=queues&batch="+arr[0]+"&qstatus="+arr[1]);
    }
  } else if (type == 'link') {
    arr = v.split(";");
    if (arr.length == 2) {
      makeLink(cell, arr[0], arr[1]);
    }
  } else if (type == 'zkbatch') {
    makeLink(cell, v, colladmin_root + "/web/zkdump.html?zkpath=/batches/" + v);
  } else if (type == 'zkjob') {
    makeLink(cell, v, colladmin_root + "/web/zkdump.html?zkpath=/jobs/" + v);
  } else if (type == 'zkacc') {
    makeLink(cell, v, colladmin_root + "/web/zkdump.html?zkpath=/access/small/" + v);
  } else if (type == 'zkacclg') {
    makeLink(cell, v, colladmin_root + "/web/zkdump.html?zkpath=/access/large/" + v);
  } else {
    cell.text(v);
  }
}

function cognitoUserAdmin(u,g) {
  api_alert(u);
  api_alert(g);
}

function ajax_invoke(p) {
  $("a.ajax:focus").attr("href", "javascript:console.log('already run')").attr("disabled", true).addClass("disabled");
  $.ajax({
    dataType: "json",
    method: "GET",
    url: decodeURIComponent(p),
    success: function(data) {
      if ('message' in data) {
        api_alert(data.message);
      }
      if ('redirect_location' in data) {
        window.location = data['redirect_location'];
      } else {
        //window.location.reload();
      }
    },
    error: function( xhr, status ) {
      api_alert(xhr.responseText);
    }
  });
}


var Report = function() {
    var self = this;
    this.makeCsv = function(rows) {
        var itemdata = "";
        rows.each(function(rownum, row){
            itemdata += (rownum == 0) ? "" : "\r\n";
            $(row).find("td,th").each(function(colnum, col){
                itemdata += self.exportCol(colnum, col);
            });
        });
        return itemdata;
    }

    this.export = function(rows) {
    var itemdata = "data:text/csv;charset=utf-8," + this.makeCsv(rows);
        var encodedUri = encodeURI(itemdata);
        window.open(encodedUri);
    }

    //this is meant to be overridden for each report
    this.exportCol = function(colnum, col) {
        var data = "";
        data += (colnum == 0) ? "" : ",";
        data += self.exportCell(col);
        return data;
    }

    this.exportCell = function(col) {
        data = "\"";
        $(col).contents().each(function(i, node){
            if ($(node).is("hr")) {
                data += "||";
            } else {
                data += $(node).text().replace(/\n/g," ").replace(/"/g,"\"\"").replace(/\s/g," ");
                if ($(node).is("div:not(:last-child)")) {
                    data += "||";
                }
            }
        });
        data += "\"";
        return data;
    }
}

function exportTable(rows) {
  var ReportObj = new Report();
  ReportObj.export(rows);
}

function show_nav_section(name) {
  var arr = name.split(";");
  var title = arr.length > 2 ? decodeURIComponent(arr[2]) : "";
  var bread = arr.length > 1 ? arr[1] : "";
  var sec = arr.length > 0 ? arr[0] : "";
  $(".nav_section, .breadpath").hide();
  $('#menu, .breadpath_home').show();
  $(sec).show();
  $(bread).show();
  $(".bp_title").text(title).show();
}
