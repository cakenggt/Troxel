# ToDo: rewrite with an MVC framework? (AngularJS)
# ToDo: Do some backgroung stuff in WebWorkers (base64 url calculation)

io = null
dragFiles = null
renderer = null
if window.applicationCache.status != window.applicationCache.UNCACHED
  window.applicationCache.addEventListener 'updateready', ->
    if window.applicationCache.status == window.applicationCache.UPDATEREADY
      if confirm "A new version of Troxel is available! Do you want to reload this page now to update?
        (You can reload this page at any time later to update to the new version.)"
        location.reload()
        clearInterval(updatechecker)
  updatechecker = setInterval (-> window.applicationCache.update()), 600000
window.onpopstate = ->
  for e in window.location.hash.replace('#','').split('&')
    [param, value] = e.split('=')
    if param == 'm' # load from base64 data
      io = new Base64IO value
      $('#btnExport').hide() if io.readonly == 1
      $('#btnExport').show() if io.readonly == 0
      $('#btnExportPng').show()
      renderer = new Renderer io
      break
    if param == 'b' # load Trove model from blueprint id
      $.getJSON 'static/Trove.json', (data) ->
        model = data[value]
        return unless model
        io = new Base64IO model
        $('#btnExport').hide()
        $('#btnExportPng').show()
        renderer = new Renderer io
      break
window.onpopstate()
$('input[type="file"]').change ->
  if $(@).prop('files').length > 1
    dragFiles = $(@).prop('files')
    $('#filetabs li:last a').tab 'show'
    $('#tabdrag ul').empty()
    $('#tabdrag ul').append $ '<li>' + f.name + '</li>' for f in dragFiles
dropFiles = document.getElementById 'openModal'
dropFiles.addEventListener 'dragover', (e) ->
  e.stopPropagation()
  e.preventDefault()
  e.dataTransfer.dropEffect = 'copy'
dropFiles.addEventListener 'drop', (e) ->
  e.stopPropagation()
  e.preventDefault()
  dragFiles = e.dataTransfer.files
  if dragFiles.length > 0
    $('#filetabs li:last a').tab 'show'
    $('#tabdrag ul').empty()
    $('#tabdrag ul').append $ '<li>' + f.name + '</li>' for f in dragFiles
$('#open').click ->
  cb = ->
    $('#openModal').modal 'hide'
    $('#btnExport').show() if !io.readonly? or io.readonly == 0
    $('#btnExportPng').show()
    renderer = new Renderer io
    history.pushState {voxels: io.voxels, x: io.x, y: io.y, z: io.z}, 'Troxel', '#m=' + new Base64IO(io).export false
  console.log '##################################################'
  switch $('#filetabs li.active a').attr('href')
    when '#tabdrag'
      if dragFiles[0].name.split('.').pop() == 'zox'
        io = new ZoxelIO dragFiles[0], cb
      else if dragFiles[0].name.split('.').pop() == 'vox'
        io = new MagicaIO dragFiles[0], cb
      else if dragFiles[0].name.split('.').pop() == 'qb'
        files = {}
        for f, i in dragFiles
          switch f.name.substr(-5)
            when '_a.qb' then files.a = f unless files.a?
            when '_t.qb' then files.t = f unless files.t?
            when '_s.qb' then files.s = f unless files.s?
            else files.m = f if f.name.substr(-3) == '.qb'
        if files.m?
          io = new QubicleIO files, cb
        else
          alert "Can't find Qubicle main mesh file!"
      else
        alert "Can't import selected file format."
    when '#tabqb'
      f = $('#fqb').prop('files')[0]
      if f and f.name.split('.').pop() == 'qb'
        io = new QubicleIO {m: f, a: f = $('#fqba').prop('files')[0], t: f = $('#fqbt').prop('files')[0], s: f = $('#fqbs').prop('files')[0]}, cb
      else
        alert 'Please choose at least a valid main mesh Qubicle (.qb) file above!'
    when '#tabvox'
      f = $('#fvox').prop('files')[0]
      if f and f.name.split('.').pop() == 'vox'
        io = new MagicaIO f, cb
      else
        alert 'Please choose a valid Magica Voxel (.vox) file above!'
    when '#tabzox'
      f = $('#fzox').prop('files')[0]
      if f and f.name.split('.').pop() == 'zox'
        io = new ZoxelIO f, cb
      else
        alert 'Please choose a valid Zoxel (.zox) file above!'
    when '#tabjson'
      io = new JsonIO $('#sjson').val()
      cb()
$('#btnExport').click ->
  $('#exportQb').text('Export as Qubicle (.qb) ...').removeAttr('href')
  $('#exportQba').hide().removeAttr('href')
  $('#exportQbt').hide().removeAttr('href')
  $('#exportQbs').hide().removeAttr('href')
  $('#exportZox').text('Export as Zoxel (.zox) ...').removeAttr('href')
  $('#exportVox').text('Export as Magica Voxel (.vox) ...').removeAttr('href')
  $('#exportBase64Ta').hide()
  $('#exportJsonTa').hide()
$('#exportQb').click ->
  return if io.readonly
  unless $(@).attr('href')?
    [href, hrefa, hreft, hrefs] = new QubicleIO(io).export($('#exportQbComp').prop('checked'))
    $(@).text('Download main mash (.qb)').attr 'href', href
    $('#exportQba').show().attr 'href', hrefa
    $('#exportQbt').show().attr 'href', hreft
    $('#exportQbs').show().attr 'href', hrefs
$('#exportZox').click ->
  return if io.readonly
  $(@).text('Download as Zoxel (.zox)').attr 'href', new ZoxelIO(io).export() unless $(@).attr('href')?
$('#exportVox').click ->
  return if io.readonly
  $(@).text('Download as Magica Voxel (.vox)').attr 'href', new MagicaIO(io).export() unless $(@).attr('href')?
$('#exportBase64').click ->
  return if io.readonly
  $('#exportBase64Ta').val(window.location.origin + '/#m=' + new Base64IO(io).export($('#exportBase64Ro').prop('checked'))).fadeIn()
$('#exportJson').click ->
  return if io.readonly
  $('#exportJsonTa').val(new JsonIO(io).export($('#exportJsonPret').prop('checked'))).fadeIn()
$('#btnExportPng').click -> renderer.render(true)
$('#ulSavedModels').parent().on 'show.bs.dropdown', (e) ->
  if $(e.relatedTarget).data('tag') == '#ulSavedModels'
    $('#ulSavedModels li:gt(6)').remove()
    $('#ulSavedModels').append '<li class="disabled"><a>No saved models</a></li>' if window.localStorage.length == 0
    for i in [0...window.localStorage.length] by 1
      key = window.localStorage.key i
      $('#ulSavedModels').append "<li><a class='openSavedModel' data-model='#{window.localStorage.getItem(key)}'>#{key}</a></li>"
  $('.openSavedModel').click ->
    io = new Base64IO $(@).data 'model'
    $('#btnExport').show() if !io.readonly? or io.readonly == 0
    $('#btnExportPng').show()
    history.pushState {voxels: io.voxels, x: io.x, y: io.y, z: io.z}, 'Toxel', '#m=' + $(@).data 'model'
    renderer = new Renderer io
    $('#ulSavedModels li:eq(1) a').text $(@).text()
$('#saveModelAs').click ->
  return unless $('#saveModelName').val().length > 0 and io?
  window.localStorage.setItem $('#saveModelName').val(), new Base64IO(io).export false
  $('#saveModal').modal 'hide'
$('#modeView').click ->
  $(@).parent().addClass('active')
  $('#modeEdit').parent().removeClass('active')
  renderer.changeEditMode(false)
  $('#addPanel').fadeOut()
$('#modeEdit').click ->
  return if io.readonly
  $(@).parent().addClass('active')
  $('#modeView').parent().removeClass('active')
  renderer.changeEditMode(true)
  $('#addPanel').fadeIn()
$('.rotateBtn').click ->
  return unless io?
  switch $(@).data('rotate')
    when  'x' then io.rotateX(true)
    when '-x' then io.rotateX(false)
    when  'y' then io.rotateY(true)
    when '-y' then io.rotateY(false)
    when  'z' then io.rotateZ(true)
    when '-z' then io.rotateZ(false)
  renderer = new Renderer io # ToDo: implement changing dimensions in renderer.reload
  history.pushState {voxels: io.voxels, x: io.x, y: io.y, z: io.z}, 'Troxel', '#m=' + new Base64IO(io).export false
$('.mirrorBtn').click ->
  return unless io?
  switch $(@).data('mirror')
    when 'x' then io.mirrorX(true)
    when 'y' then io.mirrorY(true)
    when 'z' then io.mirrorZ(true)
  renderer.reload(io)
  history.pushState {voxels: io.voxels, x: io.x, y: io.y, z: io.z}, 'Troxel', '#m=' + new Base64IO(io).export false
$('.panel-heading').click ->
  $(@).next().toggle()
$('#ambLightColor').val('#606060').change ->
  return unless io?
  renderer.ambientLight.color = new THREE.Color($(@).val())
  renderer.render()
$('#dirLightColor').val('#ffffff').change ->
  return unless io?
  renderer.directionalLight.color = new THREE.Color($(@).val())
  renderer.render()
$('#dirLightIntensity').val(1).change ->
  return unless io?
  renderer.directionalLight.intensity = $(@).val()
  renderer.render()
$('#dirLightX').val('1')
$('#dirLightY').val('0.75')
$('#dirLightZ').val('0.5')
$('#dirLightVector').click ->
  return unless io?
  renderer.directionalLight.position.set(parseFloat($('#dirLightX').val()), parseFloat($('#dirLightY').val()), parseFloat($('#dirLightZ').val())).normalize()
  renderer.render()
