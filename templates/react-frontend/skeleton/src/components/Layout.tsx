{%- if values.ui_framework == 'mui' %}
import { useState } from 'react';
import { Outlet, useNavigate, useLocation } from 'react-router-dom';
import {
  AppBar,
  Box,
  CssBaseline,
  Drawer,
  IconButton,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Toolbar,
  Typography,
  useTheme,
  useMediaQuery,
  Container,
} from '@mui/material';
import {
  Menu as MenuIcon,
  Home as HomeIcon,
  Info as InfoIcon,
  ChevronLeft as ChevronLeftIcon,
} from '@mui/icons-material';

const drawerWidth = 240;

interface NavItem {
  text: string;
  path: string;
  icon: React.ReactNode;
}

const navItems: NavItem[] = [
  { text: 'Home', path: '/', icon: <HomeIcon /> },
  { text: 'About', path: '/about', icon: <InfoIcon /> },
];

export function Layout() {
  const [mobileOpen, setMobileOpen] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));

  const handleDrawerToggle = () => {
    setMobileOpen(!mobileOpen);
  };

  const handleNavigation = (path: string) => {
    navigate(path);
    if (isMobile) {
      setMobileOpen(false);
    }
  };

  const drawer = (
    <Box>
      <Toolbar sx={{ justifyContent: 'space-between' }}>
        <Typography variant="h6" noWrap>
          ${{ values.name }}
        </Typography>
        {isMobile && (
          <IconButton onClick={handleDrawerToggle}>
            <ChevronLeftIcon />
          </IconButton>
        )}
      </Toolbar>
      <List>
        {navItems.map((item) => (
          <ListItem key={item.text} disablePadding>
            <ListItemButton
              selected={location.pathname === item.path}
              onClick={() => handleNavigation(item.path)}
            >
              <ListItemIcon>{item.icon}</ListItemIcon>
              <ListItemText primary={item.text} />
            </ListItemButton>
          </ListItem>
        ))}
      </List>
    </Box>
  );

  return (
    <Box sx={{ display: 'flex', minHeight: '100vh' }}>
      <CssBaseline />
      <AppBar
        position="fixed"
        sx={{
          width: { md: `calc(100% - ${drawerWidth}px)` },
          ml: { md: `${drawerWidth}px` },
        }}
      >
        <Toolbar>
          <IconButton
            color="inherit"
            aria-label="open drawer"
            edge="start"
            onClick={handleDrawerToggle}
            sx={{ mr: 2, display: { md: 'none' } }}
          >
            <MenuIcon />
          </IconButton>
          <Typography variant="h6" noWrap component="div">
            ${{ values.name }}
          </Typography>
        </Toolbar>
      </AppBar>
      <Box
        component="nav"
        sx={{ width: { md: drawerWidth }, flexShrink: { md: 0 } }}
      >
        <Drawer
          variant={isMobile ? 'temporary' : 'permanent'}
          open={isMobile ? mobileOpen : true}
          onClose={handleDrawerToggle}
          ModalProps={{ keepMounted: true }}
          sx={{
            '& .MuiDrawer-paper': {
              boxSizing: 'border-box',
              width: drawerWidth,
            },
          }}
        >
          {drawer}
        </Drawer>
      </Box>
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          p: 3,
          width: { md: `calc(100% - ${drawerWidth}px)` },
        }}
      >
        <Toolbar />
        <Container maxWidth="lg">
          <Outlet />
        </Container>
      </Box>
    </Box>
  );
}
{%- elif values.ui_framework == 'chakra' %}
import { useState } from 'react';
import { Outlet, useNavigate, useLocation } from 'react-router-dom';
import {
  Box,
  Flex,
  HStack,
  VStack,
  IconButton,
  Button,
  useDisclosure,
  Drawer,
  DrawerBody,
  DrawerHeader,
  DrawerOverlay,
  DrawerContent,
  DrawerCloseButton,
  Container,
  Text,
  useColorModeValue,
} from '@chakra-ui/react';
import { HamburgerIcon } from '@chakra-ui/icons';

interface NavItem {
  text: string;
  path: string;
}

const navItems: NavItem[] = [
  { text: 'Home', path: '/' },
  { text: 'About', path: '/about' },
];

export function Layout() {
  const { isOpen, onOpen, onClose } = useDisclosure();
  const navigate = useNavigate();
  const location = useLocation();
  const bgColor = useColorModeValue('white', 'gray.800');
  const borderColor = useColorModeValue('gray.200', 'gray.700');

  const handleNavigation = (path: string) => {
    navigate(path);
    onClose();
  };

  return (
    <Box minH="100vh">
      <Flex
        as="nav"
        bg={bgColor}
        borderBottom="1px"
        borderColor={borderColor}
        px={4}
        py={3}
        align="center"
        justify="space-between"
        position="fixed"
        top={0}
        left={0}
        right={0}
        zIndex={1000}
      >
        <Text fontSize="xl" fontWeight="bold">
          ${{ values.name }}
        </Text>
        <HStack spacing={4} display={{ base: 'none', md: 'flex' }}>
          {navItems.map((item) => (
            <Button
              key={item.text}
              variant={location.pathname === item.path ? 'solid' : 'ghost'}
              onClick={() => handleNavigation(item.path)}
            >
              {item.text}
            </Button>
          ))}
        </HStack>
        <IconButton
          aria-label="Open menu"
          icon={<HamburgerIcon />}
          display={{ base: 'flex', md: 'none' }}
          onClick={onOpen}
        />
      </Flex>

      <Drawer isOpen={isOpen} placement="left" onClose={onClose}>
        <DrawerOverlay />
        <DrawerContent>
          <DrawerCloseButton />
          <DrawerHeader>${{ values.name }}</DrawerHeader>
          <DrawerBody>
            <VStack align="stretch" spacing={2}>
              {navItems.map((item) => (
                <Button
                  key={item.text}
                  variant={location.pathname === item.path ? 'solid' : 'ghost'}
                  justifyContent="flex-start"
                  onClick={() => handleNavigation(item.path)}
                >
                  {item.text}
                </Button>
              ))}
            </VStack>
          </DrawerBody>
        </DrawerContent>
      </Drawer>

      <Box as="main" pt="64px">
        <Container maxW="container.lg" py={8}>
          <Outlet />
        </Container>
      </Box>
    </Box>
  );
}
{%- elif values.ui_framework == 'tailwind' %}
import { useState } from 'react';
import { Outlet, useNavigate, useLocation } from 'react-router-dom';

interface NavItem {
  text: string;
  path: string;
}

const navItems: NavItem[] = [
  { text: 'Home', path: '/' },
  { text: 'About', path: '/about' },
];

export function Layout() {
  const [mobileOpen, setMobileOpen] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();

  const handleNavigation = (path: string) => {
    navigate(path);
    setMobileOpen(false);
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="fixed top-0 left-0 right-0 z-50 bg-white border-b border-gray-200 shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex items-center">
              <span className="text-xl font-bold text-gray-900">
                ${{ values.name }}
              </span>
            </div>
            <div className="hidden md:flex items-center space-x-4">
              {navItems.map((item) => (
                <button
                  key={item.text}
                  onClick={() => handleNavigation(item.path)}
                  className={`px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                    location.pathname === item.path
                      ? 'bg-blue-100 text-blue-700'
                      : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
                  }`}
                >
                  {item.text}
                </button>
              ))}
            </div>
            <div className="flex items-center md:hidden">
              <button
                onClick={() => setMobileOpen(!mobileOpen)}
                className="p-2 rounded-md text-gray-600 hover:bg-gray-100"
                aria-label="Toggle menu"
              >
                <svg
                  className="h-6 w-6"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  {mobileOpen ? (
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M6 18L18 6M6 6l12 12"
                    />
                  ) : (
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M4 6h16M4 12h16M4 18h16"
                    />
                  )}
                </svg>
              </button>
            </div>
          </div>
        </div>
        {mobileOpen && (
          <div className="md:hidden border-t border-gray-200 bg-white">
            <div className="px-2 pt-2 pb-3 space-y-1">
              {navItems.map((item) => (
                <button
                  key={item.text}
                  onClick={() => handleNavigation(item.path)}
                  className={`block w-full text-left px-3 py-2 rounded-md text-base font-medium ${
                    location.pathname === item.path
                      ? 'bg-blue-100 text-blue-700'
                      : 'text-gray-600 hover:bg-gray-100'
                  }`}
                >
                  {item.text}
                </button>
              ))}
            </div>
          </div>
        )}
      </nav>

      <main className="pt-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <Outlet />
        </div>
      </main>
    </div>
  );
}
{%- else %}
import { useState } from 'react';
import { Outlet, useNavigate, useLocation } from 'react-router-dom';
import styles from './Layout.module.css';

interface NavItem {
  text: string;
  path: string;
}

const navItems: NavItem[] = [
  { text: 'Home', path: '/' },
  { text: 'About', path: '/about' },
];

export function Layout() {
  const [mobileOpen, setMobileOpen] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();

  const handleNavigation = (path: string) => {
    navigate(path);
    setMobileOpen(false);
  };

  return (
    <div className={styles.layout}>
      <nav className={styles.navbar}>
        <div className={styles.navContent}>
          <span className={styles.logo}>${{ values.name }}</span>
          <div className={styles.navLinks}>
            {navItems.map((item) => (
              <button
                key={item.text}
                onClick={() => handleNavigation(item.path)}
                className={`${styles.navLink} ${
                  location.pathname === item.path ? styles.active : ''
                }`}
              >
                {item.text}
              </button>
            ))}
          </div>
          <button
            className={styles.menuButton}
            onClick={() => setMobileOpen(!mobileOpen)}
            aria-label="Toggle menu"
          >
            {mobileOpen ? '✕' : '☰'}
          </button>
        </div>
        {mobileOpen && (
          <div className={styles.mobileNav}>
            {navItems.map((item) => (
              <button
                key={item.text}
                onClick={() => handleNavigation(item.path)}
                className={`${styles.mobileNavLink} ${
                  location.pathname === item.path ? styles.active : ''
                }`}
              >
                {item.text}
              </button>
            ))}
          </div>
        )}
      </nav>
      <main className={styles.main}>
        <Outlet />
      </main>
    </div>
  );
}
{%- endif %}
