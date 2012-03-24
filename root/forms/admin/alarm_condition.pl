{
    action => '/admin/alarm_condition/save',
    indicator => 'submitted',
    auto_id => 'alarm_condition_%n',
    auto_fieldset => {
        legend => 'Alarm Condition',
    },
    
    elements => [
        {
            type => 'Hidden',
            name => 'alarm_condition_id'
        },
        {
            type => 'Text',
            name => 'name',
            label => 'Name',
            # constraints => [ 'Required' ],
            attributes => { class => 'input-string' },
        },
        {
            type => 'Text',
            name => 'sensor_mask',
            label => 'Sensor Mask',
            comment => 'eg. new_york/%/temperature',
            constraints => [ 'Required' ],
            attributes => { class => 'input-string' },
        },
        {
            type => 'Text',
            name => 'max_measure_age_minutes',
            label => 'Max measure age',
            comment => 'min',
            attributes => { class => 'input-int' },
        },
        {
            type => 'Multi',
            elements => [
                {
                    type => 'Label',
                    label => 'Latest Value',
                },
                {
                    type => 'Text',
                    name => 'latest_value_gt',
                    attributes => { class => 'input-int' },
                },
                {
                    type => 'Label',
                    label => '...',
                },
                {
                    type => 'Text',
                    name => 'latest_value_lt',
                    attributes => { class => 'input-int' },
                },
            ]
        },
        {
            type => 'Multi',
            elements => [
                {
                    type => 'Label',
                    label => 'Min/Max',
                },
                {
                    type => 'Text',
                    name => 'min_value_gt',
                    attributes => { class => 'input-int' },
                },
                {
                    type => 'Label',
                    label => '...',
                },
                {
                    type => 'Text',
                    name => 'max_value_lt',
                    attributes => { class => 'input-int' },
                },
            ]
        },
        {
            type => 'Select',
            name => 'severity_level',
            label => 'Severity',
            options => [
                [ 1 => 'Info' ],
                [ 2 => 'Warn' ],
                [ 3 => 'Error' ],
                [ 4 => 'Fatal' ],
            ],
        },
        {
            type => 'Text',
            name => 'notify_email',
            label => 'Notify Email',
            # constraints => [ 'Required' ],
            attributes => { class => 'input-string' },
        },
        {
            type => 'Hidden',
            name => 'submitted',
            value => 1,
        },
        {
            type => 'Submit',
            name => 'Save',
            value => 'Save',
        },
    ],
}