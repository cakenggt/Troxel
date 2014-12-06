window.Troxel =
  webgl: -> try
    canvas = document.createElement 'canvas'
    !!(window.WebGLRenderingContext && (canvas.getContext 'webgl' || canvas.getContext 'experimental-webgl'))
  catch
    false
  renderBlueprint: (blueprintId, domElement, options) ->
    $.ajax dataType: 'jsonp', url: 'https://chrmoritz.github.io/Troxel/static/Trove.jsonp', jsonpCallback: 'callback', cache: true, success: (data) ->
      model = data[blueprintId]
      Troxel.renderBase64(model, domElement, options, blueprintId) if model?
      console.warn "blueprintId #{blueprintId} not found"
  renderBase64: (base64, domElement, options = {}, blueprintId) ->
    unless Troxel.webgl()
      console.warn "WebGL is not supported by your browser"
      return false
    domElement = $(domElement).empty().css('position', 'relative')
    io = new Base64IO base64
    renderer = new Renderer io, true, domElement
    # Options
    renderer.renderer.setClearColor options.rendererClearColor if options.rendererClearColor?
    renderer.ambientLight.color = new THREE.Color options.ambientLightColor if options.ambientLightColor?
    renderer.directionalLight.color = new THREE.Color options.directionalLightColor if options.directionalLightColor?
    renderer.directionalLight.intensity = options.directionalLightIntensity if options.directionalLightIntensity?
    if options.directionalLightVector? && options.directionalLightVector.x? && options.directionalLightVector.y? && options.directionalLightVector.z?
      renderer.directionalLight.position.set(options.directionalLightVector.x, options.directionalLightVector.y, options.directionalLightVector.z).normalize()
    if !options.autoRotate? || options.autoRotate
      renderer.controls.autoRotate = true
      renderer.controls.autoRotateSpeed = options.autoRotateSpeed if options.autoRotateSpeed?
    if !options.showInfoLabel? || options.showInfoLabel
      link = if blueprintId? then '#b=' + blueprintId else '#m=' + base64
      info = $("<div><a href='http://chrmoritz.github.io/Troxel/#{link}' target='_blank' class='troxelLink'>Open this model in Troxel</a></div>")
      domElement.append info.css position: 'absolute', bottom: '0px', width: '100%', textAlign: 'center'
    return true

$ ->
  $('div[data-troxel-blueprint]').each -> Troxel.renderBlueprint $(@).data('troxel-blueprint'), @, $(@).data('troxel-options')
  $('div[data-troxel-base64]').each -> Troxel.renderBase64 $(@).data('troxel-base64'), @, $(@).data('troxel-options')