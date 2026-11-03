-- Repeated songs are independent setlist occurrences. The JSON cases below
-- are also loaded by app/test/setlist_snapshot_diff_test.dart so the demo and
-- hosted implementation obey the same observable publication contract.
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

select is(private.setlist_diff(c -> 'previous', c -> 'current'), c -> 'expected', c ->> 'name')
from jsonb_array_elements($cases$
[
  {
    "name": "unchanged repeated song has no cross-occurrence changes",
    "previous": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 1
      },
      {
        "song_id": 1,
        "title": "A",
        "version_id": 20,
        "version": "Band",
        "key": "A",
        "bpm": 90,
        "item_id": 2
      }
    ],
    "current": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 1
      },
      {
        "song_id": 1,
        "title": "A",
        "version_id": 20,
        "version": "Band",
        "key": "A",
        "bpm": 90,
        "item_id": 2
      }
    ],
    "expected": {}
  },
  {
    "name": "only the second occurrence changes",
    "previous": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 1
      },
      {
        "song_id": 1,
        "title": "A",
        "version_id": 20,
        "version": "Band",
        "key": "A",
        "bpm": 90,
        "item_id": 2
      }
    ],
    "current": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 1
      },
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "D",
        "bpm": 100,
        "item_id": 2
      }
    ],
    "expected": {
      "version_changed": [
        {
          "title": "2. A",
          "from": "Band",
          "to": "Acoustic"
        }
      ],
      "key_changed": [
        {
          "title": "2. A",
          "from": "A",
          "to": "D"
        }
      ],
      "tempo_changed": [
        {
          "title": "2. A",
          "from": 90,
          "to": 100
        }
      ]
    }
  },
  {
    "name": "adding an identical reprise is still an addition",
    "previous": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 1
      },
      {
        "song_id": 1,
        "title": "A",
        "version_id": 20,
        "version": "Band",
        "key": "A",
        "bpm": 90,
        "item_id": 2
      }
    ],
    "current": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 1
      },
      {
        "song_id": 1,
        "title": "A",
        "version_id": 20,
        "version": "Band",
        "key": "A",
        "bpm": 90,
        "item_id": 2
      },
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 3
      }
    ],
    "expected": {
      "added": [
        "3. A"
      ]
    }
  },
  {
    "name": "removing the first occurrence leaves the second unchanged",
    "previous": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 1
      },
      {
        "song_id": 1,
        "title": "A",
        "version_id": 20,
        "version": "Band",
        "key": "A",
        "bpm": 90,
        "item_id": 2
      }
    ],
    "current": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 20,
        "version": "Band",
        "key": "A",
        "bpm": 90,
        "item_id": 2
      }
    ],
    "expected": {
      "removed": [
        "1. A"
      ]
    }
  },
  {
    "name": "swapping identical occurrences is a reorder",
    "previous": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 1
      },
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 2
      }
    ],
    "current": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 2
      },
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 1
      }
    ],
    "expected": {
      "reordered": true
    }
  },
  {
    "name": "delete and re-add is not mistaken for the old occurrence",
    "previous": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 1
      },
      {
        "song_id": 1,
        "title": "A",
        "version_id": 20,
        "version": "Band",
        "key": "A",
        "bpm": 90,
        "item_id": 2
      }
    ],
    "current": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 1
      },
      {
        "song_id": 1,
        "title": "A",
        "version_id": 20,
        "version": "Band",
        "key": "A",
        "bpm": 90,
        "item_id": 4
      }
    ],
    "expected": {
      "added": [
        "2. A"
      ],
      "removed": [
        "2. A"
      ]
    }
  },
  {
    "name": "upgrading legacy IDs alone is not a change",
    "previous": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80
      }
    ],
    "current": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 1
      }
    ],
    "expected": {}
  },
  {
    "name": "legacy original is matched even when the reprise is inserted before it",
    "previous": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80
      }
    ],
    "current": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 20,
        "version": "Band",
        "key": "A",
        "bpm": 90,
        "item_id": 2
      },
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 1
      }
    ],
    "expected": {
      "added": [
        "1. A"
      ]
    }
  },
  {
    "name": "legacy repeated songs match one-to-one",
    "previous": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80
      },
      {
        "song_id": 1,
        "title": "A",
        "version_id": 20,
        "version": "Band",
        "key": "A",
        "bpm": 90
      }
    ],
    "current": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 1
      },
      {
        "song_id": 1,
        "title": "A",
        "version_id": 20,
        "version": "Band",
        "key": "A",
        "bpm": 90,
        "item_id": 2
      }
    ],
    "expected": {}
  },
  {
    "name": "legacy snapshot missing version and tempo does not invent changes",
    "previous": [
      {
        "song_id": 1,
        "title": "A",
        "key": "G"
      }
    ],
    "current": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 1
      }
    ],
    "expected": {}
  },
  {
    "name": "mixed legacy IDs retain known identity and notice a reorder",
    "previous": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 1
      },
      {
        "song_id": 1,
        "title": "A",
        "version_id": 20,
        "version": "Band",
        "key": "A",
        "bpm": 90
      }
    ],
    "current": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 20,
        "version": "Band",
        "key": "A",
        "bpm": 90,
        "item_id": 2
      },
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 1
      }
    ],
    "expected": {
      "reordered": true
    }
  },
  {
    "name": "legacy current snapshot remains compatible",
    "previous": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 1
      },
      {
        "song_id": 1,
        "title": "A",
        "version_id": 20,
        "version": "Band",
        "key": "A",
        "bpm": 90,
        "item_id": 2
      }
    ],
    "current": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 20,
        "version": "Band",
        "key": "A",
        "bpm": 90
      },
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80
      }
    ],
    "expected": {
      "reordered": true
    }
  },
  {
    "name": "adding a different song does not imply a reorder",
    "previous": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 1
      }
    ],
    "current": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 1
      },
      {
        "song_id": 2,
        "title": "B",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 3
      }
    ],
    "expected": {
      "added": [
        "B"
      ]
    }
  },
  {
    "name": "empty old list supports addition",
    "previous": [],
    "current": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 1
      }
    ],
    "expected": {
      "added": [
        "A"
      ]
    }
  },
  {
    "name": "empty new list supports removal",
    "previous": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 1
      }
    ],
    "current": [],
    "expected": {
      "removed": [
        "A"
      ]
    }
  },
  {
    "name": "removing a legacy duplicate chooses the surviving version",
    "previous": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80
      },
      {
        "song_id": 1,
        "title": "A",
        "version_id": 20,
        "version": "Band",
        "key": "A",
        "bpm": 90
      }
    ],
    "current": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 20,
        "version": "Band",
        "key": "A",
        "bpm": 90,
        "item_id": 2
      }
    ],
    "expected": {
      "removed": [
        "1. A"
      ]
    }
  },
  {
    "name": "legacy changed key stays visible",
    "previous": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80
      }
    ],
    "current": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "D",
        "bpm": 80,
        "item_id": 1
      }
    ],
    "expected": {
      "key_changed": [
        {
          "title": "A",
          "from": "G",
          "to": "D"
        }
      ]
    }
  },
  {
    "name": "reorder and edit report the current occurrence number",
    "previous": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 1
      },
      {
        "song_id": 1,
        "title": "A",
        "version_id": 20,
        "version": "Band",
        "key": "A",
        "bpm": 90,
        "item_id": 2
      }
    ],
    "current": [
      {
        "song_id": 1,
        "title": "A",
        "version_id": 20,
        "version": "Band",
        "key": "D",
        "bpm": 90,
        "item_id": 2
      },
      {
        "song_id": 1,
        "title": "A",
        "version_id": 10,
        "version": "Acoustic",
        "key": "G",
        "bpm": 80,
        "item_id": 1
      }
    ],
    "expected": {
      "key_changed": [
        {
          "title": "1. A",
          "from": "A",
          "to": "D"
        }
      ],
      "reordered": true
    }
  }
]
$cases$::jsonb) as t(c);

insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at)
values
 ('dddd0000-0000-4000-8000-000000000001','00000000-0000-0000-0000-000000000000','authenticated','authenticated','repeat-owner@test.local','{"full_name":"Repeat Owner"}',now(),now()),
 ('dddd0000-0000-4000-8000-000000000002','00000000-0000-0000-0000-000000000000','authenticated','authenticated','repeat-member@test.local','{"full_name":"Repeat Member"}',now(),now()),
 ('dddd0000-0000-4000-8000-000000000003','00000000-0000-0000-0000-000000000000','authenticated','authenticated','repeat-outsider@test.local','{"full_name":"Repeat Outsider"}',now(),now());
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"dddd0000-0000-4000-8000-000000000001","role":"authenticated"}', true);
select set_config('test.repeat_team', public.create_team('Repeated songs QA')::text, true);
update public.teams set join_requires_approval = false where id = current_setting('test.repeat_team')::bigint;
select set_config('test.repeat_code', (select invite_code from public.teams where id = current_setting('test.repeat_team')::bigint), true);
select set_config('test.repeat_song', public.add_song(current_setting('test.repeat_team')::bigint, 'Repeated song', p_version_name=>'Acoustic', p_key=>'G', p_bpm=>80)::text, true);
select set_config('test.repeat_v1', (select id::text from public.song_versions where song_id=current_setting('test.repeat_song')::bigint), true);
insert into public.song_versions (team_id,song_id,name,default_key,bpm)
values(current_setting('test.repeat_team')::bigint,current_setting('test.repeat_song')::bigint,'Band','A',90);
select set_config('test.repeat_v2', (select id::text from public.song_versions where song_id=current_setting('test.repeat_song')::bigint and name='Band'), true);
insert into public.sessions(team_id,title,starts_at)
values(current_setting('test.repeat_team')::bigint,'Repeated song service',now()-interval '1 day');
select set_config('test.repeat_session', (select id::text from public.sessions where team_id=current_setting('test.repeat_team')::bigint), true);
insert into public.sheets(team_id,version_id,key,label,storage_path,page_count,page_sizes,size_bytes)
select current_setting('test.repeat_team')::bigint,id,default_key,name,current_setting('test.repeat_team')||'/repeat-'||id||'.pdf',1,'[[595,842]]',100
from public.song_versions where song_id=current_setting('test.repeat_song')::bigint;
select set_config('test.repeat_sheet1', (select id::text from public.sheets where version_id=current_setting('test.repeat_v1')::bigint),true);
select set_config('test.repeat_sheet2', (select id::text from public.sheets where version_id=current_setting('test.repeat_v2')::bigint),true);
insert into public.setlist_items(team_id,session_id,position,song_id,version_id,key,bpm,sheet_id)
values(current_setting('test.repeat_team')::bigint,current_setting('test.repeat_session')::bigint,1,current_setting('test.repeat_song')::bigint,current_setting('test.repeat_v1')::bigint,'G',80,current_setting('test.repeat_sheet1')::bigint);
select set_config('test.repeat_first',(select id::text from public.setlist_items where session_id=current_setting('test.repeat_session')::bigint and position=1),true);
select lives_ok($$
  insert into public.setlist_items(team_id,session_id,position,song_id,version_id,key,bpm,sheet_id)
  values(current_setting('test.repeat_team')::bigint,current_setting('test.repeat_session')::bigint,2,current_setting('test.repeat_song')::bigint,current_setting('test.repeat_v2')::bigint,'A',90,current_setting('test.repeat_sheet2')::bigint)
$$,'same song can have another version in the same setlist');
select lives_ok($$
  insert into public.setlist_items(team_id,session_id,position,song_id,version_id,key,bpm,sheet_id)
  values(current_setting('test.repeat_team')::bigint,current_setting('test.repeat_session')::bigint,3,current_setting('test.repeat_song')::bigint,current_setting('test.repeat_v1')::bigint,'B',80,current_setting('test.repeat_sheet1')::bigint)
$$,'same version can be used again with a different key');
select set_config('test.repeat_second',(select id::text from public.setlist_items where session_id=current_setting('test.repeat_session')::bigint and position=2),true);
select set_config('test.repeat_third',(select id::text from public.setlist_items where session_id=current_setting('test.repeat_session')::bigint and position=3),true);
update public.setlist_items set song_form=E'  Chorus x2\nEnding  ',notes='reprise only' where id=current_setting('test.repeat_second')::bigint;
select is((select jsonb_build_object('key',key,'bpm',bpm,'form',song_form,'notes',notes) from public.setlist_items where id=current_setting('test.repeat_first')::bigint), '{"key":"G","bpm":80,"form":null,"notes":null}'::jsonb,'editing reprise leaves original settings intact');
select throws_ok($$
  insert into public.setlist_items(team_id,session_id,position,song_id,version_id,sheet_id)
  values(current_setting('test.repeat_team')::bigint,current_setting('test.repeat_session')::bigint,4,current_setting('test.repeat_song')::bigint,current_setting('test.repeat_v1')::bigint,current_setting('test.repeat_sheet2')::bigint)
$$,'23503',null,'each occurrence still requires a sheet from its own version');
select is(public.publish_setlist(current_setting('test.repeat_session')::bigint),'{}'::jsonb,'first publication succeeds');
select is((select count(distinct e->>'item_id')::int from public.announcements a cross join lateral jsonb_array_elements(a.setlist_snapshot)e where a.session_id=current_setting('test.repeat_session')::bigint),3,'snapshot retains all three occurrence IDs');
select is((select times_played from public.song_stats where song_id=current_setting('test.repeat_song')::bigint),1,'song statistics count services, not repeated slots');
select is((select times from public.top_songs(current_setting('test.repeat_team')::bigint,now()-interval '1 month',now()+interval '1 day') where song_id=current_setting('test.repeat_song')::bigint),1,'top song statistics count services too');
select is((select count(*)::int from public.song_history where song_id=current_setting('test.repeat_song')::bigint),3,'history retains each version and key occurrence');
select is((select last_version_id from public.song_stats where song_id=current_setting('test.repeat_song')::bigint),current_setting('test.repeat_v1')::bigint,'latest version follows last occurrence in the service');
select lives_ok($$
 select public.reorder_setlist(current_setting('test.repeat_session')::bigint,array[current_setting('test.repeat_third')::bigint,current_setting('test.repeat_first')::bigint,current_setting('test.repeat_second')::bigint])
$$,'reorder uses occurrence IDs');
select is(public.publish_setlist(current_setting('test.repeat_session')::bigint),'{"reordered":true}'::jsonb,'reordering repeats causes one order change and no phantom key/version changes');
select is((select last_version_id from public.song_stats where song_id=current_setting('test.repeat_song')::bigint),current_setting('test.repeat_v2')::bigint,'latest version is deterministic after reorder');
update public.setlist_items set version_id=current_setting('test.repeat_v1')::bigint,sheet_id=current_setting('test.repeat_sheet1')::bigint,key='D',bpm=100 where id=current_setting('test.repeat_second')::bigint;
select is(public.publish_setlist(current_setting('test.repeat_session')::bigint),'{"version_changed":[{"title":"3. Repeated song","from":"Band","to":"Acoustic"}],"key_changed":[{"title":"3. Repeated song","from":"A","to":"D"}],"tempo_changed":[{"title":"3. Repeated song","from":90,"to":100}]}'::jsonb,'publish identifies only the changed occurrence by its current slot');
select is(public.publish_setlist(current_setting('test.repeat_session')::bigint),'{}'::jsonb,'repeated publication without changes stays empty');
delete from public.setlist_items where id=current_setting('test.repeat_first')::bigint;
select is(public.publish_setlist(current_setting('test.repeat_session')::bigint),'{"removed":["2. Repeated song"]}'::jsonb,'deleting one occurrence removes only that slot');
select is((select count(*)::int from public.setlist_items where session_id=current_setting('test.repeat_session')::bigint),2,'remaining duplicate slots survive deletion');
select set_config('request.jwt.claims', '{"sub":"dddd0000-0000-4000-8000-000000000002","role":"authenticated"}', true);
select public.join_team(current_setting('test.repeat_code'));
select is((select count(*)::int from public.setlist_items where session_id=current_setting('test.repeat_session')::bigint),2,'members can read each published occurrence');
select throws_ok($$ select public.publish_setlist(current_setting('test.repeat_session')::bigint) $$,'42501',null,'members still cannot publish');
select set_config('request.jwt.claims', '{"sub":"dddd0000-0000-4000-8000-000000000003","role":"authenticated"}', true);
select is((select count(*)::int from public.setlist_items where session_id=current_setting('test.repeat_session')::bigint),0,'outsiders cannot read repeated slots');
select is((select count(*)::int from public.song_history where song_id=current_setting('test.repeat_song')::bigint),0,'history view retains RLS');
select is((select count(*)::int from public.song_stats where song_id=current_setting('test.repeat_song')::bigint),0,'statistics view retains RLS');
select throws_ok($$
 insert into public.setlist_items(team_id,session_id,position,song_id,version_id)
 values(current_setting('test.repeat_team')::bigint,current_setting('test.repeat_session')::bigint,4,current_setting('test.repeat_song')::bigint,current_setting('test.repeat_v1')::bigint)
$$,'42501',null,'outsiders cannot insert repeated slots');
reset role;
select * from finish();
rollback;
