
require 'irc_logger/EyeAreSee'
require 'irc_logger/mylogger'
require 'irc_logger/prettify'
require 'irc_logger/user_colours'
require 'irc_logger/logbot'
require 'irc_logger/index_generator'

module IrcLogger
  def self.html_start(file_depth)
    %{
<html>
  <head>
    <title> Rubinius Chat Logs%s</title>
  <style>

  </style>
  <script src="#{"../"*file_depth}prototype.js"></script>
  <link rel='stylesheet' href='#{"../"*file_depth}irc.css' type='text/css' />

  </head>
<body>
<div id="header">
  <div class="fleft">Rubinius %s</div>
  <div class="fright">IRC log</div>
  <div class="noshow">Rubinius</div>
</div>
<div id="logs">
    }
  end
  
  HTML_END = %q{
</table>
</div>
  <script>$$('.doorrow').each(Element.hide);</script>
<div id="footer">
<div class="fleft"><a href="http://danlucraft.com/blog">Daniel Lucraft</a></div>
<div class="fright">

<!-- Site Meter -->
<script type="text/javascript" src="http://sm9.sitemeter.com/js/counter.js?site=sm9rublogs">
</script>
<noscript>
<a href="http://sm9.sitemeter.com/stats.asp?site=sm9rublogs" target="_top">
<img src="http://sm9.sitemeter.com/meter.asp?site=sm9rublogs" alt="Site Meter" border="0"/></a>
</noscript>
<!-- Copyright (c)2006 Site Meter -->
</div>
<div class="noshow">Da</div>

</div>

</body>
</html>
}
end