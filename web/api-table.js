var iterativeParams = [];
var urlbase = "";
var pageparams = {};

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

  if (url != '') {
    showUrl(url);
    $("#menu").hide();
  } else {
    $("#menu").show();
  }
});

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
      alert("An error has occurred.  Possibly a timeout.\n"+xhr.responseText)
      $("#in-progress").dialog("close");
    }
  });

}

function processResult(data) {
  $("h1").text(data.title);
  $("h2.report_path").text(data.report_path);

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
      data.iterate
    )
  } else {
    document.body.innerHTML = JSON.stringify(data);
  }
}

function postLoad() {
  if ($("#data-table caption").length == 0) {
    var rcount = $("#data-table tbody tr").length;
    $("<caption/>").text(rcount + " Rows").prependTo($("#data-table"));  
  }
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
        alert("An error has occurred.  Possibly a timeout.\n"+xhr.responseText)
        $("#in-progress").dialog("close");
      }
    });
  }
}

var alldata = [];
function createTable(headers, types, data, filter_col, group_col, show_grand_total, show_iterative_total, merritt_path, alternative_queries, iterate) {
  $("p.buttons")
    .show();
  $('#alternative ul').empty().hide();
  $.each(alternative_queries, function(i, q){
    var url = '';
    if (q['url'].substr(0,1) == '/'){
      url = document.location.pathname.replace(/\/[^\/]*$/, '') + q['url'];
    } else {
      url = document.location.pathname + "?" + q['url'];
    }
    $('#alternative ul').show().append(
      $("<li/>").append(
        $("<a/>").text(q['label']).attr('href', url)
      )
    );
  });
  $("#exportJson").attr("href", urlbase + document.location.search + "&format=json");
  $("#data-table")
    .empty()
    .append($("<thead/>"))
    .append($("<tbody/>"));
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
        tr.append(createCell(headers[c], types[c], true, merritt_path));
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
        tr.append(createCell(data[r][c], types[c], false, merritt_path));
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
    makeLink(cell, v, "index.html?path=collections_by_node&node="+v);
  } else if (type == 'own' && Number(v) > 0){
    makeLink(cell, v, "index.html?path=collections_by_owner&own="+v);
  } else if (type == 'mime' && !v.startsWith('--')){
    makeLink(cell, v, "index.html?path=collections_by_mime_type&mime="+v);
  } else if (type == 'gmime' && v != '' && !v.startsWith('ZZ')){
    makeLink(cell, v, "index.html?path=collections_by_mime_group&mime="+v);
  } else if (type == 'coll' && Number(v) > 0){
    makeLink(cell, v, "index.html?path=collection_details&coll="+v);
  } else if (type == 'coll-date' && Number(v) > 0){
    makeLink(cell, v, "index.html?path=objects_recent_coll&coll="+v);
  } else if (type == 'ogroup' && !v.startsWith('ZZ')){
    makeLink(cell, v, "index.html?path=collection_group_details&coll="+v);
  } else if (type == 'batch') {
    makeLink(cell, v, "index.html?path=objects_by_batch&batch="+v);
  } else if (type == 'batchnote') {
    var arr = v.split(";")
    if (arr.length == 2) {
      makeLink(cell, arr[1], "index.html?path=objects_by_batch&batch="+arr[0]);
    } else {
      cell.text(v)
    }
  } else if (type == 'jobnote') {
    var arr = v.split(";")
    if (arr.length == 2) {
      batj = arr[0].split(/\//);
      if (batj.length == 2) {
        makeLink(cell, arr[1], "index.html?path=objects_by_job&batch="+batj[0]+"&job="+batj[1]);
      } else {
        cell.text(v)
      }
    } else {
      cell.text(v)
    }
  } else if (type == 'job') {
    //todo... pass batch as well, job is not indexed
    makeLink(cell, v, "index.html?path=objects_by_job&job="+v+"&batch=x");
  } else if (type == 'qbatch') {
    makeLink(cell, v, "collIndex.html?path=batch&batch="+v);
  } else if (type == 'ldapuid') {
    makeLink(cell, v, "collIndex.html?path=ldap/user&uid="+v.replace(/^.*\(/,'').replace(/\)/,''));
  } else if (type == 'ldapcoll') {
    makeLink(cell, v, "collIndex.html?path=ldap/coll&coll="+v.replace(/^.*\(/,'').replace(/\)/,''));
  } else if (type == 'ldapark') {
    makeLink(cell, v, "collIndex.html?path=ldap/coll&ark="+v);
  } else if (type == 'qbatchnote') {
    var arr = v.split(";")
    if (arr.length == 2) {
      makeLink(cell, arr[1], "collIndex.html?path=batch&batch="+arr[0]);
    } else {
      cell.text(v)
    }
  } else if (type == 'qjob') {
    var arr = v.split("/");
    var b = arr[0];
    var j = arr.length > 1 ? arr[1] : "";
    makeLink(cell, j, "collIndex.html?path=manifest&batch="+b+"&job="+j);
  } else if (type == 'mnemonic'){
    makeLink(cell, v, merritt_path + "/m/" + v);
  } else if (type == 'ark'){
    makeLink(cell, v, merritt_path + "/m/" + encodeURIComponent(v));
    cell.addClass("hasdata");
  } else if (type == 'alert'){
    if (v.match(/!$/)) {
      cell.addClass("flag");
      v = v.replace(/!$/, '');
    }
    cell.text(v);
  } else if (type == 'profile'){
    makeLink(cell, v, "collIndex.html?path=profiles&profile=" + encodeURIComponent(v));
  } else if (type == 'list' && v != ''){
    var ul = makeUl(cell);
    $.each(v.split(","), function(i,txt){
      makeLi(ul, txt);
    });
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
  } else if (type == 'list-host' && v != ''){
    var ul = makeUl(cell);
    $.each(v.split(","), function(i,txt){
      makeLiLink(ul, txt, "index.html?path=yaml&datatype=hosts&host=" + txt);
    });
    cell.addClass("hasdata");
  } else if (type == 'ldapuidlist' && v != ''){
    var ul = makeUl(cell);
    $.each(v.split(","), function(i,txt){
      makeLiLink(ul, txt, "collIndex.html?path=ldap/user&uid=" + txt.replace(/^.*\(/,'').replace(/\)/,''));
    });
    cell.addClass("hasdata");
  } else if (type == 'status'){
    cell.addClass("status-"+v);
    cell.parent("tr").addClass("status-"+v);
    cell.text(v);
  } else {
    cell.text(v);
  }
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
