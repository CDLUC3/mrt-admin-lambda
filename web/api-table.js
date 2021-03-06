var iterativeParams = [];
var urlbase = "";
var pageparams = {};

$(document).ready(function(){
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

  if (data.format == 'report'){
    createTable(
      data.headers,
      data.types,
      data.data,
      data.filter_col,
      data.group_col,
      data.show_grand_total,
      data.merritt_path,
      data.alternative_queries,
      data.iterate
    )
  } else {
    document.body.innerHTML = JSON.stringify(data);
  }
}


function query_iterate(){
  if (iterativeParams.length == 0) {
    sorttable.makeSortable($("#data-table")[0]);
    $("#in-progress").dialog("close");
    $("#iprogress").text("");
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

function createTable(headers, types, data, filter_col, group_col, show_grand_total, merritt_path, alternative_queries, iterate) {
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
    query_iterate();
  } else {
    $("#exportJson").show();
    appendTable(headers, types, data, filter_col, group_col, show_grand_total, merritt_path);
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
    } else if (types[c] == "money" || types[c] == "dataint") {
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
  }
}

function createTotalData(types) {
  var data = [];
  for(var c=0; c<types.length; c++) {
    if (types[c] == "money" || types[c] == "dataint") {
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

function appendTable(headers, types, data, filter_col, group_col, show_grand_total, merritt_path) {
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
  query_iterate();
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
    cell.text(Number(v).toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits:2}));
    cell.addClass("hasdata");
  } else if (type == 'dataint'){
    cell.text(Number(v).toLocaleString(undefined, {minimumFractionDigits: 0, maximumFractionDigits:0}));
    cell.addClass("hasdata");
  } else if (type == 'data'){
    cell.text(Number(v).toLocaleString(undefined, {minimumFractionDigits: 0, maximumFractionDigits:0}));
    cell.addClass("hasdata");
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
  } else if (type == 'qbatch') {
    makeLink(cell, v, "collIndex.html?path=batch&batch="+v);
  } else if (type == 'qjob') {
    var arr = v.split("/");
    var b = arr[0];
    var j = arr.length > 1 ? arr[1] : "";
    makeLink(cell, j, "collIndex.html?path=job&batch="+b+"&job="+j);
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
