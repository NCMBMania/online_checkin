$(async () => {
  const applicationKey = 'YOUR_APPLICATION_KEY';
  const clientKey = 'YOUR_CLIENT_KEY';
  
  const ncmb = new NCMB(applicationKey, clientKey);
  const key = url('?key');
  if (!key) {
    alert('イベントキーが指定されていません');
    return;
  }
  const event = await ncmb.DataStore('Event').equalTo('key', key).fetch();
  $('.event .title').html(`${event.get('name')}受付`);
  $('.event .url').attr('href', `${event.get('url')}ticket`);
  $('form').on('submit', async (e) => {
    e.preventDefault();
    const number = $('#ticket_number').val();
    const attendee = await ncmb.DataStore(event.get('classname'))
      .equalTo('key', key)
      .equalTo('no', number)
      .fetch();
    if (Object.keys(attendee).length == 0) {
      alert('受付番号が確認できません。番号を確認いただくか、運営者にお問い合わせください');
      return;
    }
    attend = new (ncmb.DataStore(`${event.get('classname')}Attend`));
    await attend
      .set('attendee', attendee)
      .set('event', event)
      .save();
    $('#username').html(attendee.get('name'));
    $('#onlineUrl').attr('href', event.get('video_url'));
    $('#modal').modal('show');
  });
});
