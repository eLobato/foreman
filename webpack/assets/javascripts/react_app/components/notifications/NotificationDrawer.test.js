jest.unmock('./NotificationDrawer');

import React from 'react';
import { shallow } from 'enzyme';
import NotificationDrawer from './NotificationDrawer';
import testHelpers from '../../common/testHelpers';

function setup() {
  return shallow(<NotificationDrawer />);
}

describe('NotificationDrawer', () => {
  beforeEach(() => {
    global.sessionStorage = testHelpers.mockStorage();
  });

  xit('runs a test', () => {
    setup();
    expect(false).toBe('not implemented');
  });
});
