class Note

  NOTES: [ 16.35,    17.32,    18.35,    19.45,    20.6,     21.83,    23.12,    24.5,     25.96,    27.5,  29.14,    30.87,
           32.7,     34.65,    36.71,    38.89,    41.2,     43.65,    46.25,    49,       51.91,    55,    58.27,    61.74,
           65.41,    69.3,     73.42,    77.78,    82.41,    87.31,    92.5,     98,       103.83,   110,   116.54,   123.47,
           130.81,   138.59,   146.83,   155.56,   164.81,   174.61,   185,      196,      207.65,   220,   233.08,   246.94,
           261.63,   277.18,   293.66,   311.13,   329.63,   349.23,   369.99,   392,      415.3,    440,   466.16,   493.88,
           523.25,   554.37,   587.33,   622.25,   659.26,   698.46,   739.99,   783.99,   830.61,   880,   932.33,   987.77,
           1046.5,   1108.73,  1174.66,  1244.51,  1318.51,  1396.91,  1479.98,  1567.98,  1661.22,  1760,  1864.66,  1975.53,
           2093,     2217.46,  2349.32,  2489.02,  2637.02,  2793.83,  2959.96,  3135.96,  3322.44,  3520,  3729.31,  3951.07,
           4186.01,  4434.92,  4698.64,  4978 ]

  constructor: ->
    @note = -1
    @amp = 0.5
    @amp_t = 1
    @type = 'saw'
    @filter = 1
    @q = 2
    @pitch = 0
    @pitch_t = 0.1

  is_active: ->
    @note =! -1

  frequency: ->
    return null if @note == -1
    @NOTES[@note]


class Sequencer
  constructor: ->
    @playPos = 0
    @tracks = []
    @stepCallbacks = []
    for t in [0..3]
      track = []
      for n in [0..15]
        track.push new Note()
      @tracks.push track
  next: ->
    notes = []
    for track in @tracks
      notes.push(track[@playPos])
    @playPos = (@playPos + 1 ) % 16

    for cb in @stepCallbacks
      cb({pos: @playPos})
    notes
  addStepCallback: (cb) ->
    @stepCallbacks.push(cb)
  reset: ->
    @playPos = 0


class Player

  constructor: ->
    @sequencer = new Sequencer()
    @context = new webkitAudioContext()
    @tempo = 120

  playNote: (time)->
    notes = @sequencer.next()
    for note in notes
      (new Synth(@context)).play(note, time, @perNote)

  tick: =>
    return if not @playing
    if @context.currentTime > (@lastNote + @perNote - 0.1)
      @lastNote = @lastNote + @perNote
      @playNote(@lastNote)
    setTimeout(@tick, 0)


  play: =>
    @playStart = @context.currentTime
    @sequencer.reset()
    @perNote = 1.0 / (@tempo * 4 / 60)
    #@perNote = 1.0 / 8.0
    @playing = true
    @playNote(@playStart)
    @lastNote = @playStart
    console.log(@lastNote)
    @tick()

  stop: ->
    @playing = false

class Synth
  DECLICK: 0.001

  constructor: (context) ->
    @context = context
  play: (note, time, duration) ->
    osc = @context.createOscillator()

    oscType = switch note.type
      when 'saw' then osc.SAWTOOTH
      when 'squ' then osc.SQUARE
      when 'sin' then osc.SINE
      when 'tri' then osc.TRIANGLE
      else osc.SINE


    if note.type == 'noi'
      osc = @context.createJavaScriptNode(1024, 1, 1)
      osc.onaudioprocess = (ev) ->
        if (osc.context.currentTime > osc.noteOffTime)
          osc.onaudioprocess = null
        arr = ev.outputBuffer.getChannelData(0)
        for i in [0..arr.length]
          arr[i] = (Math.random() * 2) - 1

      osc.noteOn = (time) ->
        osc.noteOnTime = time
      osc.noteOff = (time) ->
        osc.noteOffTime = time

    else
      osc.frequency.value = note.frequency()
      osc.detune.setValueAtTime(1200 * note.pitch, time)
      osc.detune.linearRampToValueAtTime(0, time + note.pitch_t)
      osc.type = oscType

    flt = @context.createBiquadFilter()
    flt.frequency.value = note.filter * note.frequency() * 20
    flt.Q.value = note.q
    osc.connect(flt)
    

    aenv = @context.createGainNode()
    aenv.gain.value = 0.0
    
    flt.connect(aenv)
    aenv.connect(@context.destination)
    aenv.gain.setValueAtTime(0.0, time)
    aenv.gain.linearRampToValueAtTime(note.amp, time + @DECLICK)
    aenv.gain.linearRampToValueAtTime(0.0, time + @DECLICK + (note.amp_t * duration))
    osc.noteOn(time)
    osc.noteOff(time + (note.amp_t * duration) + @DECLICK)


window.onload = ->
  window.player = new Player()
  player.sequencer.tracks[0][0].note = 10
  player.sequencer.tracks[0][0].type = 'sin'
  player.sequencer.tracks[0][0].amp_t = 0.5
  player.sequencer.tracks[0][0].pitch = 3
  player.sequencer.tracks[0][0].pitch_t = 0.03

  player.sequencer.tracks[0][4].note = 10
  player.sequencer.tracks[0][4].type = 'sin'
  player.sequencer.tracks[0][4].amp_t = 0.5
  player.sequencer.tracks[0][4].pitch = 3
  player.sequencer.tracks[0][4].pitch_t = 0.03

  player.sequencer.tracks[0][8].note = 10
  player.sequencer.tracks[0][8].type = 'sin'
  player.sequencer.tracks[0][8].amp_t = 0.5
  player.sequencer.tracks[0][8].pitch = 3
  player.sequencer.tracks[0][8].pitch_t = 0.03
  
  player.sequencer.tracks[0][12].note = 10
  player.sequencer.tracks[0][12].type = 'sin'
  player.sequencer.tracks[0][12].amp_t = 0.5
  player.sequencer.tracks[0][12].pitch = 3
  player.sequencer.tracks[0][12].pitch_t = 0.03


  player.sequencer.tracks[1][4].note = 20
  player.sequencer.tracks[1][4].filter = 3
  player.sequencer.tracks[1][4].type = 'noi'

  player.sequencer.tracks[1][12].note = 20
  player.sequencer.tracks[1][12].filter = 3.5
  player.sequencer.tracks[1][12].type = 'noi'

  player.sequencer.tracks[1][0].note = 33
  player.sequencer.tracks[1][0].filter = 0.9
  player.sequencer.tracks[2][2].note = 43
  player.sequencer.tracks[1][8].note = 35
#  player.play()

  player.sequencer.addStepCallback (e) ->
    $(".steps li").removeClass('active');
    $(".steps li:nth-child(#{e.pos + 1})").addClass('active')

  document.getElementById('play').addEventListener('click', -> player.play())
  document.getElementById('stop').addEventListener('click', -> player.stop())
