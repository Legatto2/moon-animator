# Restricted animation events

This build previews a small set of sound and particle effects from animation
events. Event content is JSON data interpreted by fixed plugin code. It cannot
introduce a Luau function or select an arbitrary Roblox API.

## Enable a preview

1. Add the Sound or ParticleEmitter you want to use underneath the animated
   scene item. Each child name along the path must be unique.
2. Select an event and open its editor. Put a supported JSON program in
   **On Begin**, **On End**, or both.
3. Set **Preview: ON**, then click **Save**. The toggle is a draft choice until
   Save succeeds. New imported events open with preview OFF.
4. Play the animation. To revoke approval, open the event, set Preview OFF,
   and Save. Disabling/removing its event track also revokes approval.

The editor validates changed command text before saving and checks target
objects before granting approval. If a new batch approval fails because a
target is missing or one selected item cannot be approved, all selected grants
are revoked. The editor reports whether the text was saved even though approval
failed.

Cancel preserves previously saved text and approval. Editing source text resets
the draft preview choice OFF. An unchanged legacy event may still be renamed
or resized without deleting its source text; new arbitrary Luau text is rejected
by command validation.

Approval is not serialized into a project. Reopening/importing a project or
restarting the plugin requires fresh approval. Replacing or moving the approved
root or any target path, or changing either command string, invalidates the
grant when it is checked. Named Roblox keyframe markers are separate and do
not require this preview toggle.

Opening an already-approved event with Preview ON does not give Save permission
to renew a stale grant. If the source, target, or approval changes while the
editor is open, review it again and explicitly opt in. Source changes behind
the displayed fields require closing and reopening the editor.

## Command schema

```json
{
  "version": 1,
  "actions": [
    {"op": "sound.play", "target": ["Head", "Footstep"]},
    {"op": "particle.emit", "target": ["Muzzle", "Flash"], "count": 12}
  ]
}
```

`target` is an array of direct child names relative to the animated item. In
this example, the item is a model with a Head containing a Footstep Sound, and
a Muzzle attachment containing a Flash ParticleEmitter. Change the names to
match your own hierarchy. An empty array targets the item itself, which must
then have the correct Sound or ParticleEmitter class.

| Operation | Target | Additional field | Effect |
| --- | --- | --- | --- |
| `sound.play` | Sound | None | Start/restart the approved sound; track it for cleanup |
| `sound.stop` | Sound | None | Stop a sound owned by this event track; an already-finished sound is a no-op |
| `particle.emit` | ParticleEmitter | `count`: integer 1–100 | Emit a bounded burst |
| `particle.clear` | ParticleEmitter | None | Clear particles from the approved emitter |

For the corresponding On End program:

```json
{
  "version": 1,
  "actions": [
    {"op": "sound.stop", "target": ["Head", "Footstep"]},
    {"op": "particle.clear", "target": ["Muzzle", "Flash"]}
  ]
}
```

Empty or whitespace-only text is a no-op. `{"version":1,"actions":[]}` is also
a valid no-op. Unknown fields, duplicate/escaped schema keys, unrecognized
versions or operations, wrong target classes, malformed arrays, and nonfinite
or out-of-range counts are rejected. Paths cannot contain `Parent`, `.`, `..`,
slashes, backslashes, or control characters. ObjectValue references and
instance properties are not followed as paths.

Allowed roots are Model, BasePart, Attachment, Sound, and ParticleEmitter
instances underneath Workspace. Workspace itself, other services, and objects
outside the scene are rejected. The interpreter has no command for a network
request, module loading, script creation, source mutation, deletion, generic
property writes, game damage, or calling a user-provided function.

## Cleanup and resource limits

Stop cleans tracked sounds, including looping sounds, and clears touched
emitters. It also works when playback is already stopped. Revoking a marker or
disabling/removing its track cleans that owner's effects. Sound completion
removes tracking; a later matching stop is harmless. An event cannot take over
a sound already playing outside its track, or stop another track's sound.

ParticleEmitter:Clear affects the emitter's whole current particle population.
The plugin cannot distinguish particles it emitted from pre-existing particles
on that emitter or restore them afterward. Use a dedicated emitter for event
preview when other systems also use particle effects. These are transient
preview operations, not reversible scene edits.

| Bound | Limit |
| --- | --- |
| Text per begin/end program | 4,096 bytes |
| Actions per program | 16 |
| Target path | 8 direct-child segments, up to 128 bytes each |
| Scene lookup | At most 256 children at each path step; 64 ancestors to Workspace |
| Particle burst | 100 per action; 256 per program |
| Particle emissions per play session | 2,048 |
| Tracked sounds / touched emitters | 8 / 16 per playback handler |
| Approved markers / handler states | 128 / 16 per plugin module session |
| Timeline values for event preview | Finite integer frames, up to 1,000,000 |
| Crossed frames scanned in one update | 4,096; larger jumps skip event preview and clean that track's effects |

Each playback handler also shares token buckets across all event tracks:
16 execution attempts, 32 actions, and 256 particles of burst capacity, with
the same number of tokens replenished per second. These are burst-and-refill
budgets, not strict sliding-window maxima. Stop clears per-play totals and
effects but preserves the buckets, so repeated Stop/Play does not refill them.
Warnings are throttled. Long skipped jumps resume normal event checking from
the next valid timeline update.

Every command program is preflighted for scope, targets, ownership, and budgets
before its first effect. A Roblox method may still fail at runtime, for example
if another process destroys an instance. Such failures are caught, the marker's
grant is revoked, and its tracked effects are cleaned. Already-emitted or
cleared particles cannot be rolled back.

## Migrating old event scripts

Existing `codeBegin`/`codeEnd` strings remain stored in Moon Animator project
data. Their contents are never passed to a dynamic evaluator by this build.
Convert sound playback and particle bursts to the commands above. More complex
Luau, loops, arbitrary object/property access, and custom function calls do not
run in the event interpreter.

For custom game behavior, keep the code in a script that you own and review,
then use named animation markers as timing data. The export/import code retains
marker names and values. Roblox exposes
[`AnimationTrack:GetMarkerReachedSignal`](https://create.roblox.com/docs/animation/events)
for subscribing to a specific marker name. For example, after your own script
has selected an animation track and Sound:

```luau
local connection = animationTrack:GetMarkerReachedSignal("Footstep"):Connect(function()
    footstepSound:Play()
end)

-- Disconnect this connection when your controller is finished with the track.
-- connection:Disconnect()
```

The callback's code belongs to your game; the animation supplies only timing
and marker data. Keep accepted names and any parameters explicit, and apply
your game's normal validation to gameplay-affecting actions. This example is
guidance for game integration and is not injected into the user's place by the
plugin.

The interpreter removes the reviewed arbitrary-event-code path; it is not a
certification that the entire inherited plugin, fetched assets, or every other
project-import path is safe. See [REVIEW.md](../REVIEW.md) for that scope.
