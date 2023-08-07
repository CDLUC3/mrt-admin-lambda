This directory can be used to hold "Large Data" reports that pull JSON from S3 and display the content with bootstrap tables for filtering.

This code was previously used for the Palestinian Museum matching program.

The file included below became obsolete with the introduction of Open Search for data reporting.

## Sample lambda_function.rb code for a Large Data Report

```ruby
      # previous code for the palmu matching report
      elsif path =~ %r[/web/merritt-reports/filemimelist]
        mnemonic = myparams.fetch("mnemonic","na")
        map['MNEMONIC'] = mnemonic
        map['JSON_FILEMIME_REPORT_DATA'] = get_report_url("merritt-reports/filemimelist/#{mnemonic}.out.json")
        map['JSON_FILEMIME_REPORT_DATE'] = get_report_date("merritt-reports/filemimelist/#{mnemonic}.out.json")
```

## Sample Large Data Report

```html
<html>
  <!-- Obsolete Code -->
<head>
<link rel="stylesheet" href="//cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" integrity="sha384-1BmE4kWBq78iYhFldvKuhfTAU6auU8tT94WrHftjDbrCEXSU1oBoqyl2QvZ6jIW3" crossorigin="anonymous">
<link rel="stylesheet" href="//unpkg.com/bootstrap-table@1.22.1/dist/bootstrap-table.min.css">
<script	src="//ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js"></script>
<script src="//ajax.googleapis.com/ajax/libs/jqueryui/1.9.1/jquery-ui.min.js"></script>
<link rel="stylesheet" type="text/css" href="//ajax.googleapis.com/ajax/libs/jqueryui/1.10.3/themes/smoothness/jquery-ui.css"></link>
<style type="text/css">
h1, .home {
  text-align: center;
  background-color: #F68D2E;
  margin: 0px;
}
</style>
<!--
  Create the following and save to S3 as /merritt-reports/filemimelist/{mnemonic}.out.json
  
  var filterMimes = {"application/pdf":"100.0: application/pdf: 11"};
  const DATA = [...];
-->
<script src="{{JSON_FILEMIME_REPORT_DATA}}"></script>
<script type="text/javascript">
    $(document).ready(function(){
      $('#datatable').bootstrapTable({
              sortable: true,
              pageList: [100, 200, 500],
              pageSize: 10,
              data: DATA
      });
    });
</script>
</head>
<body>
<div>
<h1>{{MNEMONIC}} File Mime List: {{JSON_FILEMIME_REPORT_DATE}}</h1>
<div class="home"><a href="/web/index.html">Admin Tool Home</a></div>
</div>
<div>
  <div class="disp table-responsive">
    <table 
      class="table table-sm table-striped table-bordered" 
      id="datatable" 
      data-sortable="true"
      data-filter-control="true"
      data-height="600"
      data-pagination="true",
      data-show-extended-pagination="true"
      data-total-not-filtered-field="totalNotFiltered"
    >
      <thead>
        <tr>
          <th data-field="mnemonic">Mnemonic</th>
          <th data-field="mime" data-filter-control="select" data-filter-data="var:filterMimes" data-filter-order-by="server">Mime</th>
          <th data-field="ark">Ark</th>
          <th data-field="path">Path</th>
        </tr>
      </thead>
      <tbody>
         
      </tbody>
    </table>
  </div>
</div>
  <!--
    Use a bundled version of bootstrap (with popper) to allow for selectable page size
  -->
  <script src="//cdn.jsdelivr.net/npm/bootstrap@5.1.1/dist/js/bootstrap.bundle.min.js" integrity="sha384-/bQdsTh/da6pkI1MST/rWKFNjaCP5gBSY4sEBT38Q/9RBh9AH40zEOg7Hlq2THRZ" crossorigin="anonymous"></script>    
  <script src="//unpkg.com/bootstrap-table@1.22.1/dist/bootstrap-table.min.js"></script>
  <script src="//unpkg.com/bootstrap-table@1.22.1/dist/extensions/filter-control/bootstrap-table-filter-control.min.js"></script>
</body>
</html>
```