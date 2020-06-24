warning: LF will be replaced by CRLF in public/css/materialize.css.
The file will have its original line endings in your working directory
[1mdiff --git a/public/css/materialize.css b/public/css/materialize.css[m
[1mindex c084a6a..90c5ff0 100644[m
[1m--- a/public/css/materialize.css[m
[1m+++ b/public/css/materialize.css[m
[36m@@ -10191,19 +10191,37 @@[m [mul{[m
     height: 220px; [m
     overflow-y: auto; [m
   }[m
[31m-  .close {[m
[31m-    width: 15px;[m
[31m-    height: 15px;[m
[31m-    color:white;[m
[31m-    background-color: maroon;[m
[31m-    float: right;[m
[31m-    right: 0;[m
[31m-    top: 0;[m
[32m+[m[32m  .close{[m
[32m+[m[32m    display: flex;[m
[32m+[m[32m    align-items: center;[m
[32m+[m[32m    width:11px;[m
[32m+[m[32m    height:11px;[m
[32m+[m[32m    background-color:#212121;[m
[32m+[m[32m    margin: 4px;[m
     padding:0px;[m
[31m-    margin: 0em;[m
[31m-  }[m
[32m+[m[32m    -webkit-border-radius: 50px;[m
[32m+[m[32m    -moz-border-radius: 50px;[m
[32m+[m[32m    border-radius: 50px;[m
[32m+[m[32m    float:right;[m
[32m+[m[32m    -webkit-box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.14), 0 1px 5px 0 rgba(0, 0, 0, 0.12), 0 3px 1px -2px rgba(0, 0, 0, 0.2);[m
[32m+[m[32m          box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.14), 0 1px 5px 0 rgba(0, 0, 0, 0.12), 0 3px 1px -2px rgba(0, 0, 0, 0.2);[m
   [m
[31m-  .close:hover {[m
[31m-    background-color: #85221b;[m
[31m-    color: white;[m
[32m+[m[32m    }[m
[32m+[m[32m  .close:hover{[m
[32m+[m[32m    opacity: 0.50;[m
[32m+[m[32m    -moz-opacity: .50;[m
[32m+[m[32m    filter:alpha (opacity=50);[m
[32m+[m[32m  }[m
[32m+[m[32m  .close p{[m
[32m+[m[32m    text-transform: uppercase;[m
[32m+[m[32m    font: size 12px;[m
[32m+[m[32m    line-height:1px;[m
[32m+[m[32m    color:#fff;[m
[32m+[m[32m    text-decoration:none;[m
[32m+[m[32m    padding-top:0px ;[m
[32m+[m[32m    padding-left:1px ;[m
[32m+[m[32m    padding-right:1px;[m
[32m+[m[32m    padding-bottom:1px ;[m
[32m+[m[32m    text-align: right;[m
[32m+[m[32m    float: right;[m
   }[m
\ No newline at end of file[m
